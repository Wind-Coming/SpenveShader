Shader "Spenve/Cartoon"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _SColor("SpecColor", Color) = (1, 1, 1, 1)
        _Gloss("Gloss", Range(0, 1)) = 1
        _OutLineColor("OutLineColor", Color) = (0, 0, 0, 1)
        _OutLineWidth("OutLineWidth", Range(0, 0.1)) = 0.1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "LightMode"="ForwardBase"}//后面这句很必要
        LOD 100

        //outline
        Pass
        {
            cull front
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
            };
            
            fixed4 _OutLineColor;
            float _OutLineWidth;

            v2f vert (appdata v)
            {
                v2f o;
                //todo:外拓的时候会出现穿帮，目前还没想到基于这种法线外拓穿帮的解决方案
                //先转到摄像机空间再计算，然后再转到投影空间
                float4 viewPos = mul(UNITY_MATRIX_MV, v.vertex);
                float4 normal = mul(UNITY_MATRIX_MV, v.normal);
                normal.z = -0.5;
                viewPos.xyz += normalize(normal.xyz) * _OutLineWidth;
                o.vertex = mul(UNITY_MATRIX_P, viewPos);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return _OutLineColor;
            }
            ENDCG
        }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD2;
                float3 normal : TEXCOORD3;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _SColor;
            float _Gloss;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                //三种转化法线方式都可以
                //float3 normal = UnityObjectToWorldNormal(v.normal);
                //float3 normal = mul(v.normal, (float3x3)unity_WorldToObject); 
                o.normal = mul(unity_ObjectToWorld, v.normal);
                
                o.worldPos = mul(unity_ObjectToWorld, v.vertex); 
                
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 albedo = tex2D(_MainTex, i.uv);
                fixed4 col = albedo;
                
                float3 lookdir = normalize( _WorldSpaceCameraPos - i.worldPos );
                float3 lightDir = normalize(_WorldSpaceLightPos0);
                float3 hf = normalize(lookdir + lightDir);
                
                half3 normal = normalize(i.normal);
                
                col *= _LightColor0 * (dot(normal, lightDir) * 0.5 + 0.5);
                
                half dotNH = dot(hf, normal);
                
                half w = fwidth(dotNH) * 2;
                fixed4 spec = _SColor * lerp(0, 1, smoothstep(-w, w, dotNH + _Gloss - 1));

                col += spec;//这里，冯女神到书中应该是有点小问题的
                col.rgb += ShadeSH9(half4(normal, 1)) * albedo;

                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
