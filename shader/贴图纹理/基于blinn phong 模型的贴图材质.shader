// 为Shader命名
Shader "Unity Shaders Book/Chapter 7/Single Texture"
{
    Properties
    {
        // 叠加的颜色，默认为白色
        _Color ("Color Tint", Color) = (1, 1, 1, 1)
        // 纹理，类型为2D，没有纹理时，默认用白色覆盖物体的表面
        _MainTex("Main Tex", 2D) = "white" {}
        // 高光颜色，默认为白色
        _Specular ("Specular", Color) = (1, 1, 1, 1)
        // 光泽度，影响高光反射区域的大小
        _Gloss ("Gloss", Range(8.0, 256)) = 20
    }

    SubShader
    {
        Pass
        {
            // 指明当前Pass的光照模式
            Tags { "LightMode" = "ForwardBase"}

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            // 为了使用光照相关的内置变量（如：_LightColor0 光照颜色）
            #include "Lighting.cginc"

            /* 定义属性变量 */
            fixed4 _Color;
            sampler2D _MainTex;
            // 与_MainTex配套的纹理缩放（scale）和平移（translation），在材质面板的纹理属性中可以调节
            // 命名规范为：纹理变量名 + "_ST"
            // _MainTex_ST.xy 存储缩放值
            // _MainTex_ST.zw 存储偏移值
            float4 _MainTex_ST;
            fixed4 _Specular;
            float _Gloss;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                // 存储模型的第一组纹理坐标，可以理解为_MainTex对应的原始纹理坐标
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                // 存储纹理坐标的UV值，可在片元着色器中使用该坐标进行纹理采样
                float2 uv : TEXCOORD2;
            };

            v2f vert(a2v v)
            {
                v2f o;

                // 将顶点坐标由模型空间转到裁剪空间
                o.pos = UnityObjectToClipPos(v.vertex);
                // 将法线由模型空间转到世界空间
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                // 将顶点坐标由模型空间转到世界空间
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                // 通过缩放和平移后的纹理UV值
                o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                // 也可以调用内置宏TRANSFORM_TEX，得到缩放和平移后的纹理UV值，与上面的计算逻辑是一致的
                // 内置宏的定义：
                // #define TRANSFORM_TEX(tex, name) (tex.xy * name##_ST.xy + name##_ST.zw)
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                fixed3 worldNormal = normalize(i.worldNormal);
                // 调用内置函数UnityWorldSpaceLightDir，
                // 得到当前坐标点在世界空间下的光照方向，并进行归一化
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

                // 通过内置函数tex2D，根据当前坐标点的UV值，对纹理进行采样拿到纹理颜色
                // 并和颜色属性的乘积得到反射率albedo
                fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;

                // 使用内置变量UNITY_LIGHTMODEL_AMBIENT，
                // 得到环境光的颜色，并和反射率相乘得到环境光部分
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                
                // 使用内置变量_LightColor0得到光照颜色，乘以反射率，得到光照部分，
                // 再根据兰伯特定律漫反射公式得到漫反射部分
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(worldNormal, worldLightDir));

                // 使用内置函数UnityWorldSpaceViewDir得到当前坐标点的视角方向，并进行归一化
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                // 基于Blinn-Phong光照模型，得到中间矢量
                fixed3 halfDir = normalize(worldLightDir + viewDir);
                // 基于Blinn-Phong光照模型的公式，得到高光反射部分
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);

                // 环境光 + 漫反射 + 高光反射，得到最终的颜色值
                return fixed4(ambient + diffuse + specular, 1.0);
            }

            ENDCG
        }
    }

    // 用系统内置的高光shader作为兜底
    Fallback "Specular"
}