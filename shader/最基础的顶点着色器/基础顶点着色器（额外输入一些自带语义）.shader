Shader "Unity Shaders Book/Chapter 5/Simple Shader Struct"
{
    SubShader
    {
        Pass
        {
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            // 使用结构体作为顶点着色器的输入，可以包含更多顶点信息
            // a2v 是当前结构体的名字，可自行定义（写法：struct [StructName]）
            // 这里 a2v 表示 application to vertex ，意思是：把数据从应用阶段传递到顶点着色器中
            struct a2v
            {
                // 模型空间的顶点坐标，相当于之前顶点着色器的输入v
                float4 vertex : POSITION;
                // 模型空间中，该顶点的法线方向，使用 NORMAL 语义
                float3 normal : NORMAL;
                // 该模型的第一套纹理坐标（模型可以有多套纹理坐标），第n+1套纹理坐标，用语义 TEXCOORDn
                float4 texcoord : TEXCOORD0;

                // 结构体里变量的书写格式：
                // Type Name : Semantic;
            };
            // Unity支持的语义有：
            // POSITION 、 NORMAL 、 TANGENT 、 TEXCOORD0 、 TEXCOORD1 、 TEXCOORD2 、 TEXCOORD3 、 COLOR 等

            // 使用结构体作为输入参数，不需要写语义，因为语义在结构体里已经声明了
            float4 vert(a2v v) : SV_POSITION
            {
                // 从结构体中取当前顶点的模型空间坐标，将其转为裁剪空间下的坐标
                return UnityObjectToClipPos(v.vertex);
            }

            fixed4 frag() : SV_Target
            {
                return fixed4(1.0, 1.0, 1.0, 1.0);
            }

            ENDCG
        }
    }
}