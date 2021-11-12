Shader "Spenve/Post/GrainyBlur"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BlurRadius("Radius", Range(0, 0.1)) = 1
        _Iteration("Iteration", Range(1, 10)) = 2
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

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
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            sampler2D _MainTex;
            float _BlurRadius;
            int _Iteration;

            fixed4 frag (v2f i) : SV_Target
            {
                half random = sin(dot(i.uv, fixed2(1233.224, 1743.335)));
                
                half2 offset = fixed2(0, 0);
                fixed4 col = 0;
                
                for(int x = 0; x < _Iteration; x++)
                {
                    random = frac(random * 368.523);
                    offset.x = (random - 0.5) * 2;
                    random = frac(random * 368.523);
                    offset.y = (random - 0.5) * 2;
                    col += tex2D(_MainTex, i.uv + offset * _BlurRadius);
                }
                return col / _Iteration;
            }
            ENDCG
        }
    }
}
