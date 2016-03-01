Shader "Spectrum"
{
    Properties
    {
        [KeywordEnum(Type1,Type2,Type3,Type4)] _Spectrum("Spectrum", Float) = 0
    }
    CGINCLUDE

    #pragma multi_compile _SPECTRUM_TYPE1 _SPECTRUM_TYPE2 _SPECTRUM_TYPE3 _SPECTRUM_TYPE4

    #include "UnityCG.cginc"

    half Luma1(half3 c)
    {
    #if defined(UNITY_NO_LINEAR_COLORSPACE)
        return dot(c, unity_ColorSpaceLuminance.rgb);
    #else
        c *= unity_ColorSpaceLuminance.rgb;
        return dot(lerp(c, sqrt(c), unity_ColorSpaceLuminance.a), 1);
    #endif
    }

    half Luma2(half3 c)
    {
    #if defined(UNITY_NO_LINEAR_COLORSPACE)
        return dot(c, unity_ColorSpaceLuminance.rgb);
    #else
        half3 rec709 = half3(0.212, 0.701, 0.087);
        half3 linc = LinearToGammaSpace(c);
        return dot(lerp(c, linc, unity_ColorSpaceLuminance.a), rec709);
    #endif
    }

    struct appdata
    {
        float4 vertex : POSITION;
        float2 uv : TEXCOORD0;
    };

    struct v2f
    {
        float4 vertex : SV_POSITION;
        float2 uv : TEXCOORD0;
    };

    v2f vert(appdata v)
    {
        v2f o;
        o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
        o.uv = v.uv;
        return o;
    }

    fixed4 frag(v2f i) : SV_Target
    {
        float is_linear = unity_ColorSpaceLuminance.a;

        half3 c = i.uv.xyx;
        c = lerp(c, GammaToLinearSpace(c), is_linear);

        #if _SPECTRUM_TYPE2
        c = Luminance(c);
        #elif _SPECTRUM_TYPE3
        c = Luma1(c);
        #elif _SPECTRUM_TYPE4
        c = Luma2(c);
        #endif

        c += frac(10 * c) < 0.5;
        return half4(c, 1);
    }

    ENDCG
    SubShader
    {
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            ENDCG
        }
    }
}
