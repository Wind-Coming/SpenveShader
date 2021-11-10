Shader "Spenve/PBR"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _MetalTex ("Metal", 2D) = "white" {}
        _Roughness("Roughness", Range(0, 1)) = 1
        _Metal("Metal", Range(0, 1)) = 0
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
            sampler2D _MetalTex;
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
            
            float GGX(float dotxx, float k)
            {
                return dotxx / (dotxx * (1 - k) + k);
            }
            
            half3 ComputeDisneyDiffuseTerm(half nv,half nl,half lh,half roughness,half3 baseColor)
            {
                half Fd90 = 0.5f + 2 * roughness * lh * lh;
                return baseColor * UNITY_INV_PI * (1 + (Fd90 - 1) * pow(1-nl,5)) * (1 + (Fd90 - 1) * pow(1-nv,5));
            }
            
            inline half OneMinusReflectivityFromMetallic(half metallic)
            {
                // We'll need oneMinusReflectivity, so
                //   1-reflectivity = 1-lerp(dielectricSpec, 1, metallic) = lerp(1-dielectricSpec, 0, metallic)
                // store (1-dielectricSpec) in unity_ColorSpaceDielectricSpec.a, then
                //   1-reflectivity = lerp(alpha, 0, metallic) = alpha + metallic*(0 - alpha) =
                //                  = alpha - metallic * alpha
                half oneMinusDielectricSpec = unity_ColorSpaceDielectricSpec.a;
                return oneMinusDielectricSpec - metallic * oneMinusDielectricSpec;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 albedo = tex2D(_MainTex, i.uv);
                fixed4 col = albedo;
                
                fixed4 metalCol = tex2D(_MetalTex, i.uv);
                fixed metal = _Metal * metalCol.r;
                                
                //half
                float3 normal = normalize(i.normal);
                float3 viewDir = normalize( _WorldSpaceCameraPos - i.worldPos );
                float3 lightDir = normalize(_WorldSpaceLightPos0);
                float3 hf = normalize(viewDir + lightDir);
                
                float dotNH = max(dot(normal, hf), 0);
                float dotHL = ( dot(lightDir, hf) );

                float dotNL = max(dot(normal, lightDir), 0);
                float dotNV = max(dot(normal, viewDir), 0);
                                
                //分母
                float denomitor = 4 * dotNV * dotNL;
                
                //法线分布
                float pow2Roughness = pow2(_Roughness);
                float denom = UNITY_PI * pow2(pow2(dotNH) * (pow2Roughness - 1) + 1);
                float D = pow2Roughness / denom;
                
                //阴影遮罩
                float k = pow2(_Roughness + 1) / 8;
                float G = GGX(dotNV, k) * GGX(dotNL, k);
                
                //菲尼尔，金属度越高，菲尼尔效果弱
                //metal = 1时，f0 = albedo(贴图里为白色，可以理解为金属反色光), F为白色，此时spcular靠其他两位D和G支撑，这也应证了金属受菲尼尔影响较小。
                //metal = 0时，f0 = 0.04，F就中间黑，边缘白（球体是这样），此时中间的specular就取决于光泽度了
                fixed3 f0 = lerp(unity_ColorSpaceDielectricSpec.rgb, albedo.rgb, metal);//区分金属非金属
                fixed3 F = f0 + (1 - f0) * pow5(1 - dotNV);
                
                col.rgb *= (1 - F)*(1 - metal) / UNITY_PI;
                col.rgb += D * G * F / denomitor;
                
                //漫反射
                col *= UNITY_PI * _LightColor0 * dotNL;
 
                //雾
                UNITY_APPLY_FOG(i.fogCoord, col);
                
                return col;
            }
            ENDCG
        }
    }
}
