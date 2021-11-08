Shader "Spenve/PlaneReflection"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Speed("Speed", float) = 1
        _Intensity("Intensity", float) = 1
    }
    
	SubShader
	{
		Tags { "RenderType" = "Opaque" }

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"
            //没有这一句将无法接收阴影
            #pragma multi_compile_fwdbase
            #include "AutoLight.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float4 screenPos: TEXCOORD0;
                float2 uv : TEXCOORD1;
                SHADOW_COORDS(2)
			};

			sampler2D _ReflectionTex;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Speed;
            float _Intensity;

			v2f vert(appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.screenPos = ComputeScreenPos(o.pos);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex) + fixed2(_Speed, _Speed) * _Time.y;
                TRANSFER_SHADOW(o)
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
                fixed4 dis = tex2D(_MainTex, i.uv);
				fixed4 col = tex2D(_ReflectionTex,  i.screenPos.xy / i.screenPos.w + dis.xy * _Intensity);
                fixed shadow = SHADOW_ATTENUATION(i);
				return col * shadow;
			}
			ENDCG
		}
		
		//手动投射阴影
        Pass
        {
            Tags {"LightMode"="ShadowCaster"}

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_shadowcaster
            #include "UnityCG.cginc"

            struct v2f { 
                V2F_SHADOW_CASTER;
            };

            v2f vert(appdata_base v)
            {
                v2f o;
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                SHADOW_CASTER_FRAGMENT(i)
            }
            ENDCG
        }
	}
}
