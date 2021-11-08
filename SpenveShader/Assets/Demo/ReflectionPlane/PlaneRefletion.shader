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

			struct appdata
			{
				float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float4 screenPos: TEXCOORD0;
                float2 uv : TEXCOORD1;
			};

			sampler2D _ReflectionTex;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Speed;
            float _Intensity;

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.screenPos = ComputeScreenPos(o.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex) + fixed2(_Speed, _Speed) * _Time.y;
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
                fixed4 dis = tex2D(_MainTex, i.uv);
				fixed4 col = tex2D(_ReflectionTex,  i.screenPos.xy / i.screenPos.w + dis.xy * _Intensity);
				return col;
			}
			ENDCG
		}
	}
}
