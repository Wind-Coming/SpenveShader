Shader "Spenve/PBR"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Roughness("Roughness", float) = 1
        _Metal("Metal", float) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

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
            float _Roughness;
            float _Metal;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex); 
                
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            float pow2(float x)
            {
                return x * x;
            }
            
            float pow5(float x)
            {
                return x * x * x * x * x;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                
                float pi = 3.1415926;

                //base,漫反射部分，迪斯尼计算公式
                col /= pi;
                
                //half
                float3 normal = normalize(i.normal);
                float3 viewDir = normalize( _WorldSpaceCameraPos - i.worldPos );
                float3 lightDir = normalize(_WorldSpaceLightPos0);
                float3 hf = normalize(viewDir + lightDir);
                
                float dotNH = ( dot(normal, hf));
                float dotHL = ( dot(lightDir, hf) );
                //float fd90 = 0.5 + 2 * _Roughness * pow2(dotHL);

                float dotNL = (dot(normal, lightDir));
                //float nv = 1 + (fd90 - 1) * pow5( 1 - dotNL);
                float dotNV = (dot(normal, viewDir));
                //float nl = 1 + (fd90 - 1) * pow5( 1 - dotNV);
                
                float denomitor = 4 * dotNV * dotNL;
                
                float pow2Roughness = pow2(_Roughness);
                float D = pow2Roughness / (pi * pow2(pow2(dotNH) * (pow2Roughness - 1) + 1));
                
                float k = pow2(_Roughness + 1) / 8;
                float G = dotNL * dotNV / (lerp(dotNL, 1, k) * lerp(dotNV, 1, k));
                
                float f0 = lerp(fixed3(0.04, 0.04, 0.04), col, _Metal);
                float F = lerp(pow5( 1 - dotNV), 1, f0);
                
                col += D * G * F / denomitor;
                
                //col *= nv * nl;
                col *= _LightColor0 * dotNL;
 
                UNITY_APPLY_FOG(i.fogCoord, col);
                
                return col;
            }
            ENDCG
        }
    }
}
