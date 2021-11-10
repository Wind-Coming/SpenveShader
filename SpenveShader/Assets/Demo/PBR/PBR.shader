Shader "Spenve/PBR"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BumpMap("Normal Map", 2D) = "bump" {}
        _MetalTex ("Metal", 2D) = "white" {}//r 金属 a粗糙度  可以合并到其他贴图
        _Smoothness("Smoothness", Range(0, 1)) = 1
        _Metal("Metal", Range(0, 1)) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "LightMode" = "ForwardBase"}
        LOD 100


        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
			#pragma multi_compile_fwdbase

            #include "UnityCG.cginc"
		    #include "Lighting.cginc"
		    #include "AutoLight.cginc"
		    
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
            
            //计算环境光照或光照贴图uv坐标
            inline half4 VertexGI(float2 uv1,float2 uv2,float3 worldPos,float3 worldNormal)
            {
                half4 ambientOrLightmapUV = 0;
    
                //如果开启光照贴图，计算光照贴图的uv坐标
                #ifdef LIGHTMAP_ON
                    ambientOrLightmapUV.xy = uv1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
                    //仅对动态物体采样光照探头,定义在UnityCG.cginc
                #elif UNITY_SHOULD_SAMPLE_SH
                    //计算非重要的顶点光照
                    #ifdef VERTEXLIGHT_ON
                        //计算4个顶点光照，定义在UnityCG.cginc
                        ambientOrLightmapUV.rgb = Shade4PointLights(
                            unity_4LightPosX0,unity_4LightPosY0,unity_4LightPosZ0,
                            unity_LightColor[0].rgb,unity_LightColor[1].rgb,unity_LightColor[2].rgb,unity_LightColor[3].rgb,
                            unity_4LightAtten0,worldPos,worldNormal);
                    #endif
                    //计算球谐光照，定义在UnityCG.cginc
                    ambientOrLightmapUV.rgb += ShadeSH9(half4(worldNormal,1));
                #endif
    
                //如果开启了 动态光照贴图，计算动态光照贴图的uv坐标
                #ifdef DYNAMICLIGHTMAP_ON
                    ambientOrLightmapUV.zw = uv2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
                #endif
    
                return ambientOrLightmapUV;
            }
            
            //计算间接光漫反射
            inline half3 ComputeIndirectDiffuse(half4 ambientOrLightmapUV,half occlusion)
            {
                half3 indirectDiffuse = 0;
    
                //如果是动态物体，间接光漫反射为在顶点函数中计算的非重要光源
                #if UNITY_SHOULD_SAMPLE_SH
                    indirectDiffuse = ambientOrLightmapUV.rgb;	
                #endif
    
                //对于静态物体，则采样光照贴图或动态光照贴图
                #ifdef LIGHTMAP_ON
                    //对光照贴图进行采样和解码
                    //UNITY_SAMPLE_TEX2D定义在HLSLSupport.cginc
                    //DecodeLightmap定义在UnityCG.cginc
                    indirectDiffuse = DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap,ambientOrLightmapUV.xy));
                #endif
                #ifdef DYNAMICLIGHTMAP_ON
                    //对动态光照贴图进行采样和解码
                    //DecodeRealtimeLightmap定义在UnityCG.cginc
                    indirectDiffuse += DecodeRealtimeLightmap(UNITY_SAMPLE_TEX2D(unity_DynamicLightmap,ambientOrLightmapUV.zw));
                #endif
    
                //将间接光漫反射乘以环境光遮罩，返回
                return indirectDiffuse * occlusion;
            }

            //重新映射反射方向
            inline half3 BoxProjectedDirection(half3 worldRefDir,float3 worldPos,float4 cubemapCenter,float4 boxMin,float4 boxMax)
            {
                //使下面的if语句产生分支，定义在HLSLSupport.cginc中
                UNITY_BRANCH
                if(cubemapCenter.w > 0.0)//如果反射探头开启了BoxProjection选项，cubemapCenter.w > 0
                {
                    half3 rbmax = (boxMax.xyz - worldPos) / worldRefDir;
                    half3 rbmin = (boxMin.xyz - worldPos) / worldRefDir;
    
                    half3 rbminmax = (worldRefDir > 0.0f) ? rbmax : rbmin;
    
                    half fa = min(min(rbminmax.x,rbminmax.y),rbminmax.z);
    
                    worldPos -= cubemapCenter.xyz;
                    worldRefDir = worldPos + worldRefDir * fa;
                }
                return worldRefDir;
            }
            //采样反射探头
            //UNITY_ARGS_TEXCUBE定义在HLSLSupport.cginc,用来区别平台
            inline half3 SamplerReflectProbe(UNITY_ARGS_TEXCUBE(tex),half3 refDir,half roughness,half4 hdr)
            {
                roughness = roughness * (1.7 - 0.7 * roughness);
                half mip = roughness * 6;
                //对反射探头进行采样
                //UNITY_SAMPLE_TEXCUBE_LOD定义在HLSLSupport.cginc，用来区别平台
                half4 rgbm = UNITY_SAMPLE_TEXCUBE_LOD(tex,refDir,mip);
                //采样后的结果包含HDR,所以我们需要将结果转换到RGB
                //定义在UnityCG.cginc
                return DecodeHDR(rgbm,hdr);
            }
            //计算间接光镜面反射
            inline half3 ComputeIndirectSpecular(half3 refDir,float3 worldPos,half roughness,half occlusion)
            {
                half3 specular = 0;
                //重新映射第一个反射探头的采样方向
                half3 refDir1 = BoxProjectedDirection(refDir,worldPos,unity_SpecCube0_ProbePosition,unity_SpecCube0_BoxMin,unity_SpecCube0_BoxMax);
                //对第一个反射探头进行采样
                half3 ref1 = SamplerReflectProbe(UNITY_PASS_TEXCUBE(unity_SpecCube0),refDir1,roughness,unity_SpecCube0_HDR);
                //如果第一个反射探头的权重小于1的话，我们将会采样第二个反射探头，进行混合
                //使下面的if语句产生分支，定义在HLSLSupport.cginc中
                UNITY_BRANCH
                if(unity_SpecCube0_BoxMin.w < 0.99999)
                {
                    //重新映射第二个反射探头的方向
                    half3 refDir2 = BoxProjectedDirection(refDir,worldPos,unity_SpecCube1_ProbePosition,unity_SpecCube1_BoxMin,unity_SpecCube1_BoxMax);
                    //对第二个反射探头进行采样
                    half3 ref2 = SamplerReflectProbe(UNITY_PASS_TEXCUBE_SAMPLER(unity_SpecCube1,unity_SpecCube0),refDir2,roughness,unity_SpecCube1_HDR);
    
                    //进行混合
                    specular = lerp(ref2,ref1,unity_SpecCube0_BoxMin.w);
                }
                else
                {
                    specular = ref1;
                }
                return specular * occlusion;
            }
            
            //计算间接光镜面反射菲涅尔项
            inline half3 ComputeFresnelLerp(half3 c0,half3 c1,half cosA)
            {
                half t = pow(1 - cosA,5);
                return lerp(c0,c1,t);
            }

            //inline half OneMinusReflectivityFromMetallic(half metallic)
            //{
                // We'll need oneMinusReflectivity, so
                //   1-reflectivity = 1-lerp(dielectricSpec, 1, metallic) = lerp(1-dielectricSpec, 0, metallic)
                // store (1-dielectricSpec) in unity_ColorSpaceDielectricSpec.a, then
                //   1-reflectivity = lerp(alpha, 0, metallic) = alpha + metallic*(0 - alpha) =
                //                  = alpha - metallic * alpha
            //    half oneMinusDielectricSpec = unity_ColorSpaceDielectricSpec.a;
            //    return oneMinusDielectricSpec - metallic * oneMinusDielectricSpec;
            //}
            
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
 				float2 texcoord1 : TEXCOORD1;
				float2 texcoord2 : TEXCOORD2;
           };

            struct v2f
            {
                float2 uv : TEXCOORD0;
				half4 ambientOrLightmapUV : TEXCOORD1;//存储环境光或光照贴图的UV坐标
                UNITY_FOG_COORDS(4)
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD2;
                float3 normal : NORMAL;
                half3 tspace0 : TEXCOORD3;
                half3 tspace1 : TEXCOORD4;
                half3 tspace2 : TEXCOORD5;            
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _BumpMap;
            sampler2D _MetalTex;
            float _Smoothness;
            float _Metal;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex); 
                
				//计算环境光照或光照贴图uv坐标
				o.ambientOrLightmapUV = VertexGI(v.texcoord1,v.texcoord2, o.worldPos, o.normal);
				
				half3 wTangent = UnityObjectToWorldDir(v.tangent.xyz);
                half tangentSign = v.tangent.w * unity_WorldTransformParams.w;
                half3 wBitangent = cross(o.normal, wTangent) * tangentSign;
                o.tspace0 = half3(wTangent.x, wBitangent.x, o.normal.x);
                o.tspace1 = half3(wTangent.y, wBitangent.y, o.normal.y);
                o.tspace2 = half3(wTangent.z, wBitangent.z, o.normal.z);
                
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 albedo = tex2D(_MainTex, i.uv);
                fixed4 col = albedo;
                
                fixed4 metalCol = tex2D(_MetalTex, i.uv);
                fixed metal = _Metal * metalCol.r;
                fixed roughness = 1 - _Smoothness * metalCol.a;
                                
                //normal
                half3 tnormal = UnpackNormal(tex2D(_BumpMap, i.uv));
                half3 normal;
                normal.x = dot(i.tspace0, tnormal);
                normal.y = dot(i.tspace1, tnormal);
                normal.z = dot(i.tspace2, tnormal);
                
                //half
                float3 viewDir = normalize( _WorldSpaceCameraPos - i.worldPos );
                float3 lightDir = normalize(_WorldSpaceLightPos0);
                float3 hf = normalize(viewDir + lightDir);
                
                float dotNH = saturate(dot(normal, hf));
                float dotHL = saturate( dot(lightDir, hf) );

                float dotNL = saturate(dot(normal, lightDir));
                float dotNV = saturate(dot(normal, viewDir));
                                
                //分母
                float denomitor = 4 * dotNV * dotNL + 0.00001;
                
                //法线分布
                float pow2Roughness = pow2(roughness);
                float denom = UNITY_PI * pow2(pow2(dotNH) * (pow2Roughness - 1) + 1);
                float D = pow2Roughness / denom;
                
                //阴影遮罩
                float k = pow2(roughness + 1) / 8;
                float G = GGX(dotNV, k) * GGX(dotNL, k);
                
                //菲尼尔，金属度越高，菲尼尔效果弱
                //metal = 1时，f0 = albedo(贴图里为白色，可以理解为金属反色光), F为白色，此时spcular靠其他两位D和G支撑，这也应证了金属受菲尼尔影响较小。
                //metal = 0时，f0 = 0.04，F就中间黑，边缘白（球体是这样），此时中间的specular就取决于光泽度了
                fixed3 f0 = lerp(unity_ColorSpaceDielectricSpec.rgb, albedo.rgb, metal);//反射率
                fixed3 F = f0 + (1 - f0) * pow5(1 - dotNV);
                
                //漫反射
                col.rgb *= (1 - F) * (1 - metal) / UNITY_PI;
                
                col.rgb += D * G * F / denomitor;
                
                //漫反射
                col *= UNITY_PI * _LightColor0 * dotNL;
                
                
                //镜面反射
 				half3 refDir = reflect(-viewDir, normal);//世界空间下的反射方向
                fixed3 indirectSpecular = ComputeIndirectSpecular(refDir, i.worldPos, roughness, 1);//镜面反射,1 需要换成ao
                
                //f0的反射率
				half oneMinusReflectivity = (1- metal) * unity_ColorSpaceDielectricSpec.a;
				//计算间接光镜面反射
				indirectSpecular *= F;

				//计算环境光
				half3 indirectDiffuse = ComputeIndirectDiffuse(i.ambientOrLightmapUV, 1);
				indirectDiffuse *= albedo * oneMinusReflectivity;

                col.rgb += indirectDiffuse;
                col.rgb += indirectSpecular;
 
                //雾
                UNITY_APPLY_FOG(i.fogCoord, col);
                
                return fixed4(col.rgb, 1);
            }
            ENDCG
        }
    }
	FallBack "VertexLit"
}
