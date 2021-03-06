// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Spenve/Reflection"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
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

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD1;
                float3 worldNormal : NORMAL;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            float3 BoxProjectedCubemapDirection (float3 worldRefl, float3 worldPos, float4 cubemapCenter, float4 boxMin, float4 boxMax)
            {
                // Do we have a valid reflection probe?
                //UNITY_BRANCH
                if (cubemapCenter.w > 0.0)
                {
                    float3 nrdir = normalize(worldRefl);
            
                    #if 1
                        float3 rbmax = (boxMax.xyz - worldPos) / nrdir;
                        float3 rbmin = (boxMin.xyz - worldPos) / nrdir;
            
                        float3 rbminmax = (nrdir > 0.0f) ? rbmax : rbmin;
            
                    #else // Optimized version
                        float3 rbmax = (boxMax.xyz - worldPos);
                        float3 rbmin = (boxMin.xyz - worldPos);
            
                        float3 select = step (float3(0,0,0), nrdir);
                        float3 rbminmax = lerp (rbmax, rbmin, select);
                        rbminmax /= nrdir;
                    #endif
            
                    float fa = min(min(rbminmax.x, rbminmax.y), rbminmax.z);
            
                    worldPos -= cubemapCenter.xyz;
                    worldRefl = worldPos + nrdir * fa;
                }
                return worldRefl;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                half3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                half3 worldRef = reflect(-worldViewDir, i.worldNormal);
                //worldRef = BoxProjectedCubemapDirection(worldRef, i.worldPos, unity_SpecCube1_ProbePosition,
                //unity_SpecCube1_BoxMin, unity_SpecCube1_BoxMax);
                
                half4 skydata = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, worldRef);
                half3 skyColor = DecodeHDR(skydata, unity_SpecCube0_HDR);
                
                fixed4 col = 1;
                col.rgb = skyColor;
                
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
