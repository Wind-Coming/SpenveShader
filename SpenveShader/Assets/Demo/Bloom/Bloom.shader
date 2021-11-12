Shader "Spenve/Post/Bloom"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BlurRadius("Radius", Range(0, 5)) = 1
        _LuminanceThreshold("LuminanceThreshold", Range(0, 1)) = 0.5
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass //0
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float2 uv1 : TEXCOORD1;
                float2 uv2 : TEXCOORD2;
                float2 uv3 : TEXCOORD3;
                float2 uv4 : TEXCOORD4;
            };
            
            sampler2D _MainTex;
	        float4 _MainTex_TexelSize;
	        float _BlurRadius;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.uv1 = v.uv + _MainTex_TexelSize * _BlurRadius * float2(-1, -1);
                o.uv2 = v.uv + _MainTex_TexelSize * _BlurRadius * float2(-1, 1);
                o.uv3 = v.uv + _MainTex_TexelSize * _BlurRadius * float2(1, 1);
                o.uv4 = v.uv + _MainTex_TexelSize * _BlurRadius * float2(1, -1);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv) * 4;
                col += tex2D(_MainTex, i.uv1);
                col += tex2D(_MainTex, i.uv2);
                col += tex2D(_MainTex, i.uv3);
                col += tex2D(_MainTex, i.uv4);
                return col * 0.125;
            }
            ENDCG
        }
        
        Pass//1
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 uv1 : TEXCOORD1;
                float4 uv2 : TEXCOORD2;
                float4 uv3 : TEXCOORD3;
                float4 uv4 : TEXCOORD4;
            };
            
            sampler2D _MainTex;
	        float4 _MainTex_TexelSize;
	        float _BlurRadius;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.uv1.xy = v.uv + _MainTex_TexelSize * _BlurRadius * float2(-1, -1);
                o.uv2.xy = v.uv + _MainTex_TexelSize * _BlurRadius * float2(-1, 1);
                o.uv3.xy = v.uv + _MainTex_TexelSize * _BlurRadius * float2(1, 1);
                o.uv4.xy = v.uv + _MainTex_TexelSize * _BlurRadius * float2(1, -1);
                
                o.uv1.zw = v.uv + _MainTex_TexelSize * _BlurRadius * float2(-1, 0);
                o.uv2.zw = v.uv + _MainTex_TexelSize * _BlurRadius * float2(1, 0);
                o.uv3.zw = v.uv + _MainTex_TexelSize * _BlurRadius * float2(0, 1);
                o.uv4.zw = v.uv + _MainTex_TexelSize * _BlurRadius * float2(0, -1);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = 0;
                col += tex2D(_MainTex, i.uv1.xy) * 2;
                col += tex2D(_MainTex, i.uv2.xy) * 2;
                col += tex2D(_MainTex, i.uv3.xy) * 2;
                col += tex2D(_MainTex, i.uv4.xy) * 2;
                
                col += tex2D(_MainTex, i.uv1.zw);
                col += tex2D(_MainTex, i.uv2.zw);
                col += tex2D(_MainTex, i.uv3.zw);
                col += tex2D(_MainTex, i.uv4.zw);
                return col * 0.0833333;
            }
            ENDCG
        }
        
        Pass //2
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };
            
            sampler2D _MainTex;
	        float _LuminanceThreshold;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed Luminance(fixed4 col)
            {
                return 0.2125 * col.r + 0.7154 * col.g + 0.0721 * col.b;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                fixed lu = Luminance(col);
                return col * saturate(lu - _LuminanceThreshold);
            }
            ENDCG
        }
        
        Pass //3
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };
            
            sampler2D _MainTex;
            sampler2D _BlurTex;
            float _Intensity;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv) + tex2D(_BlurTex, i.uv) * _Intensity;
                return col;
            }
            ENDCG
        }
    }
}
