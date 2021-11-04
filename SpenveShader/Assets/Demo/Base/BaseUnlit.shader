Shader "Spenve/BaseUnlit"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        //常见tag：
        //Queue:Background,Geometry,AlphaTest,Transparent,Overlay
        //RenderType:RenderType tag可以用自定义的字符串，在使用ShadeReplacement，全局替换渲染的时候有用。
        //IgnoreProjector Unity 有种Projector 投影效果，如果加上这个Tag，那么就不会受到投影影响。
        //LightMode tag 渲染路径标签， 一般现在渲染分为了 三类，顶点渲染路径，向前的渲染，对于的延迟渲染路径。
        //Always: Always rendered; no lighting is applied.
        //ForwardBase: Used in Forward rendering, 　　ambient, main directional light, vertex/SH lights and lightmaps are applied. 只受到环境光，主要（强度最大那个）的方向光，球协光照和lightMap影响
        //ForwardAdd: Used in Forward rendering; additive per-pixel lights are applied, one pass per light. 如果灯光类型是 NO-IMPORT 或者其他类型光源 就会用到这个
        //Deferred: Used in Deferred Shading; renders g-buffer. 延迟渲染的，渲染到Gbuffer
        //ShadowCaster: Renders object depth into the shadowmap or a depth texture. 生成阴影要用深度图shader
        //MotionVectors: Used to calculate per-object motion vectors. 计算物件移动向量
        //PrepassBase: Used in legacy Deferred Lighting, renders normals and specular exponent. 
        //PrepassFinal: Used in legacy Deferred Lighting, renders final color by combining textures, lighting and emission.
        //Vertex: Used in legacy Vertex Lit rendering when object is not lightmapped; all vertex lights are applied.
        //VertexLMRGBM: Used in legacy Vertex Lit rendering when object is lightmapped; on platforms where lightmap is RGBM encoded (PC & console).
        //VertexLM: Used in legacy Vertex Lit rendering when object is lightmapped; on platforms where lightmap is double-LDR encoded (mobile platforms).


        Tags { "RenderType"="Opaque" "IgnoreProjector"="true" "LightMode"="Always"}
        LOD 100
        //声明命令 当前像素 * 因子1 缓存像素 * 因子2
        //Blend 因子1 因子2
        //可选的混合操作，默认Add，该操作决定上面 当前像素与缓存像素的处理关系
        //BlendOp Add
        //Blend DstColor Zero正片叠底，也就是 当前颜色 * 缓存颜色 + 缓存颜色 * 0
        //BlendOp Sub

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
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
