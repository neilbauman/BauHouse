import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

/**
 * update-premium-status
 *
 * Called by RevenueCat webhook when a subscription event occurs.
 * Updates player.is_premium based on the entitlement status.
 *
 * RevenueCat sends events like:
 *   INITIAL_PURCHASE, RENEWAL, CANCELLATION, EXPIRATION, etc.
 *
 * The webhook secret is verified to ensure authenticity.
 */
Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Verify webhook secret
    const webhookSecret = Deno.env.get("REVENUECAT_WEBHOOK_SECRET");
    const authHeader = req.headers.get("authorization");

    if (webhookSecret && authHeader !== `Bearer ${webhookSecret}`) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const body = await req.json();

    // RevenueCat webhook payload structure
    const event = body.event;
    if (!event) {
      return new Response(
        JSON.stringify({ error: "Missing event in payload" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const eventType: string = event.type;
    const appUserId: string | undefined = event.app_user_id;
    const productId: string | undefined = event.product_id;

    if (!appUserId) {
      return new Response(
        JSON.stringify({ error: "Missing app_user_id" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Determine premium status based on event type
    const activatingEvents = new Set([
      "INITIAL_PURCHASE",
      "RENEWAL",
      "UNCANCELLATION",
      "NON_RENEWING_PURCHASE",
      "SUBSCRIPTION_EXTENDED",
      "TRANSFER",
    ]);

    const deactivatingEvents = new Set([
      "EXPIRATION",
      "BILLING_ISSUE",
      "PRODUCT_CHANGE", // May need manual review
    ]);

    let isPremium: boolean | null = null;

    if (activatingEvents.has(eventType)) {
      isPremium = true;
    } else if (deactivatingEvents.has(eventType)) {
      isPremium = false;
    } else if (eventType === "CANCELLATION") {
      // Cancellation means they won't renew, but access continues until expiry
      // Don't change is_premium yet — EXPIRATION will handle it
      isPremium = null;
    }

    if (isPremium === null) {
      // Acknowledged but no action needed
      return new Response(
        JSON.stringify({
          success: true,
          message: `Event ${eventType} acknowledged, no status change.`,
        }),
        {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Update the player record
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    const { error } = await supabase
      .from("players")
      .update({
        is_premium: isPremium,
        updated_at: new Date().toISOString(),
      })
      .eq("id", appUserId);

    if (error) {
      console.error("Failed to update player:", error);
      return new Response(
        JSON.stringify({ error: "Database update failed", details: error.message }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    console.log(
      `Premium status updated: player=${appUserId}, ` +
      `event=${eventType}, is_premium=${isPremium}, ` +
      `product=${productId || "unknown"}`
    );

    return new Response(
      JSON.stringify({
        success: true,
        player_id: appUserId,
        is_premium: isPremium,
        event_type: eventType,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (err) {
    console.error("Webhook error:", err);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
