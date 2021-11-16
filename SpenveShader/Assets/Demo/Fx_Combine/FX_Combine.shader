Shader "Spenve/FX_Combine"
{
	Properties
	{
		[Enum(UnityEngine.Rendering.BlendMode)]_Src("Src", float) = 5
		[Enum(UnityEngine.Rendering.BlendMode)]_Dst("Dst", float) = 10
		[Enum(UnityEngine.Rendering.CullMode)]_Cull("Cull", float) = 2
		[Enum(Off,0,On,1)] _ZWrite("Z Write", float) = 0
		[Enum(UnityEngine.Rendering.CompareFunction)] _ZTest("ZTest", float) = 4 //"LessEqual"
		[Toggle] _UseCustomdata("Use Customdata", float) = 0

		[HDR]_Color("Color", Color) = (1,1,1,1)
		[NoScaleOffset]_MainTexture("Main Texture", 2D) = "white" {}
		_MainUV("Main UV(A1,A2)", Vector) = (1,1,0,0)
		[Toggle(_UVANIMATION_ON)] _UVAnimation("UV Animation", float) = 0
		[Toggle]_Loop("Loop",float) = 1

		[Toggle(_USEDISSOLVE_ON)] _UseDissolve("Use Dissolve", float) = 0
		[HDR]_EdgeColor("Edge Color", Color) = (1,0,0,1)
		[NoScaleOffset]_DissolveMap("Dissolve Map", 2D) = "white" {}
		_DissolveUV("Dissolve UV", Vector) = (1,1,0,0)
		_Clip("Clip (A3)", Range(-1 , 1)) = 0
		_EdgeRange("Edge Range", Range(0 , 1)) = 0.2
		[Toggle]_EnableTwist("Enable Twist", float) = 0

		[Toggle(_USEMASK_ON)] _UseMask("Use Mask", float) = 0
		[NoScaleOffset]_MaskMap("Mask Map", 2D) = "white" {}
		_MaskUV("Mask UV", Vector) = (1,1,0,0)

		[Toggle(_USETWIST_ON)] _UseTwist("Use Twist", float) = 0
		[NoScaleOffset]_TwistMap("Twist Map", 2D) = "white" {}
		_TwistUV("Twist UV", Vector) = (1,1,0,0)
		_TwistStrength("Twist Strength", Range(0 , 2)) = 0.15

		[Toggle(_USERIM_ON)] _UseRim("UseRim",float) = 0
		[Toggle] _ApplyAlpha("ApplyAlpha",float) = 0
		[HDR]_FresnelColor("Rim Color", Color) = (0.5,0.5,1,1)
		_FresnelRange("Rim Range", Range(0 , 5)) = 1
	}

	SubShader
	{
		Tags { "RenderType" = "Transparent" "Queue" = "Transparent" "IgnoreProjector" = "True" "PreviewType" = "Plane"}

		CGINCLUDE
		#pragma target 2.0
		#include "UnityCG.cginc"
		#include "UnityShaderVariables.cginc"
		ENDCG

		Blend [_Src] [_Dst]
		Cull [_Cull]
		ZWrite [_ZWrite]
		ZTest [_ZTest]
		
		Pass
		{
			Name "FXCombine"
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_instancing

			#pragma shader_feature_local _ _USEDISSOLVE_ON
			#pragma shader_feature_local _ _USETWIST_ON
			#pragma shader_feature_local _ _USERIM_ON
			#pragma shader_feature_local _ _UVANIMATION_ON
			#pragma shader_feature_local _ _USEMASK_ON

			struct appdata
			{
				half4 vertex : POSITION;
				half3 normal : NORMAL;
				half4 color : COLOR;
				half4 uv : TEXCOORD0;
				half4 customDataA : TEXCOORD1;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f
			{
				half4 vertex : SV_POSITION;
				half4 worldPos : TEXCOORD0;
				half4 vertexColor : TEXCOORD1;
				half4 worldNormal : TEXCOORD2;
				half4 texcoord1 : TEXCOORD3;
				half2 texcoord2 : TEXCOORD4;//有新的可以改成half4，zw可以使用
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			uniform half _Src;
			uniform half _Dst;
			uniform half _Cull;
			uniform int _UseCustomdata;
			uniform sampler2D _MainTexture;
			uniform half4 _MainUV;
			uniform half4 _Color;

			#ifdef _UVANIMATION_ON
				uniform half _Loop;
			#endif

			#ifdef _USEDISSOLVE_ON
				uniform sampler2D _DissolveMap;
				uniform half4 _DissolveUV;
				uniform half _Clip;
				uniform half4 _EdgeColor;
				uniform half _EdgeRange;
				uniform half _EnableTwist;
			#endif

			#ifdef _USEMASK_ON
				uniform sampler2D _MaskMap;
				uniform half4 _MaskUV;
			#endif

			#ifdef _USETWIST_ON
				uniform sampler2D _TwistMap;
				uniform half4 _TwistUV;
				uniform half _TwistStrength;
			#endif

			#ifdef _USERIM_ON
				uniform half _FresnelRange;
				uniform half4 _FresnelColor;
				uniform half _ApplyAlpha;
			#endif

			v2f vert ( appdata v )
			{
				v2f o = (v2f)0;
				UNITY_SETUP_INSTANCE_ID(v);
				#ifdef _USERIM_ON
					o.worldPos.xyz = mul(unity_ObjectToWorld, v.vertex).xyz;
				#endif
				//custom data A1,A2 : UV offset
				#ifdef _UVANIMATION_ON
					o.texcoord1.zw = v.uv.zw * _UseCustomdata;
				#endif

				//custom data A3,A4 : Dissolve Rate , DissolveEdgeSoft
				//custom data B3,B2 : Dissolve UV SPEED
				#ifdef _USEDISSOLVE_ON
					v.customDataA *= _UseCustomdata;
					o.worldNormal.w = v.customDataA.x;//溶解率
					o.worldPos.w = v.customDataA.y;//溶解边缘宽度
					o.texcoord2.x = v.customDataA.z;//溶解贴图U方向速度
					o.texcoord2.y = v.customDataA.w;//溶解贴图V方向速度
				#endif
				o.vertexColor = v.color;
				o.texcoord1.xy = v.uv.xy;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.worldNormal.xyz = normalize(UnityObjectToWorldNormal(v.normal));
				return o;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(i);
				//Main UV
				#ifdef _UVANIMATION_ON
					half2 offset = lerp(_MainUV.zw + i.texcoord1.zw, _Time.y * (_MainUV.zw + i.texcoord1.zw), _Loop);
					half2 mainUV = i.texcoord1.xy * _MainUV.xy + offset;
				#else
					half2 mainUV = i.texcoord1.xy;
				#endif

				//Twist UV
				#ifdef _USETWIST_ON
					half2 twistUV = i.texcoord1.xy * _TwistUV.xy + _Time.y * _TwistUV.zw;
					half4 _twistMap = tex2D(_TwistMap, twistUV);
					//通过灰度图生成UV贴图
					half2 _UOffset = half2(twistUV.x + 0.1, twistUV.y);
					half2 _VOffset = half2(twistUV.x, twistUV.y + 0.1);
					half3 _twistU = half3(1, 0, (tex2D(_TwistMap, _UOffset) - _twistMap).g * _TwistStrength);
					half3 _twistV = half3(0, 1, (tex2D(_TwistMap, _VOffset) - _twistMap).g * _TwistStrength);
					half2 finalTwistUV = normalize(cross(_twistU, _twistV)).xy;
					//计算UV
					mainUV -= finalTwistUV;
					half4 finalMap = tex2D(_MainTexture, mainUV) * _Color * i.vertexColor;
				#else
					half4 finalMap = tex2D(_MainTexture, mainUV) * _Color * i.vertexColor;
				#endif

				//Dissolve
				#ifdef _USEDISSOLVE_ON
					half2 _dissolveUV = i.texcoord1.xy * _DissolveUV.xy + (_DissolveUV.zw + i.texcoord2.xy) * _Time.y;
					#ifdef _USETWIST_ON
						_dissolveUV -= finalTwistUV * _EnableTwist;
					#endif
					half dissolveMap = tex2D(_DissolveMap, _dissolveUV).r + (_Clip + i.worldNormal.w) * 1.001;
					//计算宽度
					half finalEdge = dissolveMap / saturate(_EdgeRange + i.worldPos.w + 0.0001);
					//计算溶解
					finalMap.xyz = lerp(_EdgeColor, finalMap, saturate(finalEdge + 1 - _EdgeColor.w)).xyz;
					finalMap.w *= saturate(finalEdge);
				#endif

				//Mask
				#ifdef _USEMASK_ON
					half2 _maskUV = i.texcoord1.xy * _MaskUV.xy + _MaskUV.zw;
					half maskMap = tex2D(_MaskMap, _maskUV).r;
					finalMap.w *= maskMap;
				#endif

				//Fresnel
				#ifdef _USERIM_ON
					half3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
					half4 finalFresnel = pow(1 - abs(dot(i.worldNormal.xyz, worldViewDir)), _FresnelRange) * _FresnelColor;
					half fresnelAlpha = _ApplyAlpha == 1 ? finalMap.w : 1;
					finalMap += finalFresnel * fresnelAlpha;
				#endif
				return half4(finalMap.xyz, saturate(finalMap.w));
			}
			ENDCG
		}
	}
	CustomEditor "FX_Combine_Inspector"
}