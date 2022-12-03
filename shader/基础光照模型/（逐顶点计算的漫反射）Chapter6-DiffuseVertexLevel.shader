// 给Shader命名
Shader "Unity Shaders Book/Chapter 6/Diffuse Vertex-Level"
{
    Properties
    {
        // 漫反射颜色的属性，默认为白色
        _Diffuse("Diffuse", Color) = (1, 1, 1, 1)
    }
    
    SubShader
    {
        Pass
        {
            // LightMode用于定义该Pass在Unity的光照流水线中的角色
            // 后续会详细地了解，这里有个概念即可
            // 只有定义了正确的LightMode，才能得到一些Unity的内置光照变量
            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM

            // 声明顶点/片元着色器的方法名
            #pragma vertex vert
            #pragma fragment frag

            // 为了使用Unity内置的一些变量，比如：_LightColor0
            #include "Lighting.cginc"

            // 声明属性变量
            fixed4 _Diffuse;

            struct a2v
            {
                // 顶点坐标
                float4 vertex : POSITION;
                // 顶点法线矢量
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                // 顶点着色器输出的颜色值
                // 这里不是必须使用COLOR语义，也可以使用TEXCOORD0语义
                fixed3 color : COLOR;
            };

            v2f vert (a2v v)
            {
                v2f o;
                // 将顶点坐标由模型空间转到裁剪空间
                o.pos = UnityObjectToClipPos(v.vertex);

                // 通过Unity内置变量得到环境光的颜色值
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                // 将法线由模型空间转到世界空间，并进行归一化（法线的矩阵转换需要使用逆矩阵来实现）
                // 交换矢量和矩阵的相乘顺序来实现相同的效果
                // 因为法线是三维矢量，所以只需截取对应矩阵的前三行前三列即可
                fixed3 worldNormal = normalize(mul(v.normal, (float3x3)unity_WorldToObject));
                // 通过内置变量_WorldSpaceLightPos0获取世界空间下的光源方向，并进行归一化
                // 因为本案例中光源是平行光，所以可以直接取该变量进行归一化，若是其他类型光源，计算方式会有不同
                fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);
                // 使用漫反射公式得到漫反射的颜色值
                // 通过内置变量_LightColor0，拿到光源的颜色信息
                // saturate，为取值范围限定[0, 1]的函数
                // dot，为矢量点积的函数，只有两个矢量处于同一坐标空间，点积才有意义
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal, worldLight));

                // 最后对环境光和漫反射光部分相加，得到最终的光照结果
                o.color = ambient + diffuse;

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // 将顶点输出的颜色值作为片元着色器的颜色输出，输出到屏幕上
                return fixed4(i.color, 1.0);
            }

            ENDCG
        }
    }

    // 使用内置的Diffuse作为保底着色器
    Fallback "Diffuse"
}