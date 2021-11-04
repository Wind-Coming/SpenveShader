Shader "Spenve/LambertWithAmbient"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "LightMode"="ForwardBase"}//后面这句很必要
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
            //没有这一句将无法接收阴影
            #pragma multi_compile_fwdbase
            #include "AutoLight.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float4 color : COLOR;
                SHADOW_COORDS(1)
                UNITY_FOG_COORDS(2)
           };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                //三种转化法线方式都可以
                //float3 normal = UnityObjectToWorldNormal(v.normal);
                //float3 normal = mul(v.normal, (float3x3)unity_WorldToObject); 
                float3 normal = mul(unity_ObjectToWorld, v.normal);
                
                float h = max(0, dot(v.normal, normalize(_WorldSpaceLightPos0)));
                o.color = _LightColor0 * h;
                o.color.rgb += ShadeSH9(half4(normal, 1));
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                TRANSFER_SHADOW(o)
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                fixed shadow = SHADOW_ATTENUATION(i);
                col *= shadow;
                
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col * i.color;
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
