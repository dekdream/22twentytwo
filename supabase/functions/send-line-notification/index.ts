import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { message } = await req.json();

    if (typeof message !== "string" || message.trim().length === 0) {
      return Response.json(
        { error: "message is required" },
        { status: 400, headers: corsHeaders },
      );
    }

    const supabase = createClient(
      Deno.env.get("URL")!,
      Deno.env.get("SERVICE_ROLE_KEY")!,
    );
    const { data: users, error } = await supabase
      .from("line_users")
      .select("user_id");

    if (error) throw error;

    const token = Deno.env.get("LINE_CHANNEL_ACCESS_TOKEN");
    if (!token) throw new Error("LINE_CHANNEL_ACCESS_TOKEN is not configured");

    const results = await Promise.all(
      (users ?? []).map(async ({ user_id }) => {
        const response = await fetch("https://api.line.me/v2/bot/message/push", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${token}`,
          },
          body: JSON.stringify({
            to: user_id,
            messages: [{ type: "text", text: message.trim() }],
          }),
        });

        if (!response.ok) {
          throw new Error(`LINE push failed (${response.status}): ${await response.text()}`);
        }
      }),
    );

    return Response.json(
      { success: true, total: results.length },
      { headers: corsHeaders },
    );
  } catch (error) {
    console.error(error);
    return Response.json(
      { success: false, error: String(error) },
      { status: 500, headers: corsHeaders },
    );
  }
});
