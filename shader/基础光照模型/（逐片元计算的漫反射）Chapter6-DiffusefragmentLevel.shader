// 修改着色器的名字
Shader "Unity Shaders Book/Chapter 6/Diffuse Pixel-Level"
{
    Properties
    {
        _Diffuse("Diffuse", Color) = (1, 1, 1, 1)
    }
    
    SubShader
    {
        Pass
        {
            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"

            fixed4 _Diffuse;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                // 顶点着色器输出的世界空间下的法线
                // 用于在片元着色器中编写光照计算逻辑
                fixed3 worldNormal : TEXCOORD0;
            };

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                // 顶点着色器只需要计算世界空间下的法线矢量，并传递给片元着色器即可
                o.worldNormal = mul(v.normal, (float3x3)unity_WorldToObject);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // 获取环境光颜色
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                
                // 将世界空间下的法线矢量进行归一化
                fixed3 worldNormal = normalize(i.worldNormal);
                // 通过内置变量_WorldSpaceLightPos0获取世界空间下的光照方向，并进行归一化
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);

                // 根据漫反射同时计算漫反射颜色值
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal, worldLightDir));

                // 将环境光和漫反射光相加，输出到屏幕
                fixed3 color = ambient + diffuse;
                return fixed4(color, 1.0);
            }

            ENDCG
        }
    }

    Fallback "Diffuse"
}