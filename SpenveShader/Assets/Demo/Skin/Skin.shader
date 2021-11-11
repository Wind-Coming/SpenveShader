Shader "Spenve/Skin"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Lut("Lut", 2D) = "white" {}
        _Gloss("Gloss", float) = 1
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
            float _Gloss;
            sampler2D _Lut;

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
                fixed4 col = tex2D(_MainTex, i.uv);
                
                float3 lookdir = normalize( _WorldSpaceCameraPos - i.worldPos );
                float3 lightDir = normalize(_WorldSpaceLightPos0);
                float3 hf = normalize(lookdir + lightDir);
                
                col *= _LightColor0 * max(0, dot(i.normal, lightDir));
                
                float nwidth = length(fwidth(i.normal));
                float pwidth = length(fwidth(i.worldPos));
                float curve = _Gloss * nwidth / pwidth;
                
                float4 uv = float4(dot(i.normal, lightDir) * 0.5 + 0.5, curve, 0, 0);
                fixed4 c = tex2Dlod(_Lut, uv);
                col.rgb *= c.rgb;
                
                col += pow( max(0, dot(hf, i.normal)), _Gloss);

                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
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
