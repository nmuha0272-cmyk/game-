// The horror camera look: bloom (lights glow), filmic tone mapping, a cold
// color grade, a dark vignette, film grain and a little lens color fringing.
// Used by SZGraphics.cs (SZPostEffect). Pass 0 = final image, 1 = bright
// parts (for bloom), 2 = blur.
Shader "Hidden/Deepwell/HorrorPost"
{
    Properties
    {
        _MainTex ("Image", 2D) = "white" {}
    }

    CGINCLUDE
    #include "UnityCG.cginc"

    sampler2D _MainTex;
    float4 _MainTex_TexelSize;
    sampler2D _BloomTex;
    float _Exposure;
    float _BloomStrength;
    float _BloomThreshold;
    float _Vignette;
    float _Grain;
    float _Fringe;
    float _Saturation;
    float4 _Tint;
    float _Seed;
    float _Damage;   // red edges when you're caught
    float _Flash;    // white flash (camera flash, being caught)

    float3 Aces(float3 x)
    {
        const float a = 2.51, b = 0.03, c = 2.43, d = 0.59, e = 0.14;
        return saturate((x * (a * x + b)) / (x * (c * x + d) + e));
    }

    float Random(float2 p)
    {
        return frac(sin(dot(p, float2(12.9898, 78.233))) * 43758.5453);
    }

    float4 FragFinal(v2f_img i) : SV_Target
    {
        float2 uv = i.uv;
        float2 fromCenter = uv - 0.5;
        float3 col;
        col.r = tex2D(_MainTex, uv + fromCenter * _Fringe).r;
        col.g = tex2D(_MainTex, uv).g;
        col.b = tex2D(_MainTex, uv - fromCenter * _Fringe).b;
        col += tex2D(_BloomTex, uv).rgb * _BloomStrength;

        col = Aces(col * _Exposure);
        float grey = dot(col, float3(0.299, 0.587, 0.114));
        col = lerp(grey.xxx, col, _Saturation) * _Tint.rgb;

        float edge = saturate(dot(fromCenter, fromCenter) * 2.6);
        col *= 1.0 - edge * _Vignette;
        col = lerp(col, float3(0.45, 0.0, 0.0), edge * _Damage);

        float noise = Random(uv * _ScreenParams.xy * 0.5 + _Seed) - 0.5;
        col += noise * _Grain * (1.0 - grey * 0.5);
        col = lerp(col, float3(1, 1, 1), _Flash);
        return float4(col, 1);
    }

    float4 FragBright(v2f_img i) : SV_Target
    {
        float2 o = _MainTex_TexelSize.xy * 0.5;
        float3 c = (tex2D(_MainTex, i.uv + float2(-o.x, -o.y)).rgb + tex2D(_MainTex, i.uv + float2(o.x, -o.y)).rgb +
                    tex2D(_MainTex, i.uv + float2(-o.x, o.y)).rgb + tex2D(_MainTex, i.uv + float2(o.x, o.y)).rgb) * 0.25;
        float bright = max(c.r, max(c.g, c.b));
        float keep = saturate((bright - _BloomThreshold) / max(bright, 0.0001));
        return float4(c * keep, 1);
    }

    float4 FragBlur(v2f_img i) : SV_Target
    {
        float2 o = _MainTex_TexelSize.xy * 1.5;
        float3 c = tex2D(_MainTex, i.uv).rgb * 0.2;
        c += tex2D(_MainTex, i.uv + float2(o.x, o.y)).rgb * 0.2;
        c += tex2D(_MainTex, i.uv + float2(-o.x, o.y)).rgb * 0.2;
        c += tex2D(_MainTex, i.uv + float2(o.x, -o.y)).rgb * 0.2;
        c += tex2D(_MainTex, i.uv + float2(-o.x, -o.y)).rgb * 0.2;
        return float4(c, 1);
    }
    ENDCG

    SubShader
    {
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment FragFinal
            ENDCG
        }
        Pass
        {
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment FragBright
            ENDCG
        }
        Pass
        {
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment FragBlur
            ENDCG
        }
    }
    Fallback Off
}
