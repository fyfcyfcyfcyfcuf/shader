// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

shader"Unity Shaders Book/Chapter 5/MY Shader"{
    subshader {
        pass{
            CGPROGRAM

            #pragma vertex vert
            //将顶点着色器的函数定义为 vert（基本格式为：#pragma vertex/fragment name）；
            #pragma fragment frag
            //将片元着色器的函数定义为 frag；
           
           
            float4 vert(float4 v : POSITION) : SV_POSITION{
                //POSITION:向cpu发送指令请求调用顶点信息；
                //SV_POSITION：将获得的顶点信息再向后传递至片元着色器；
                
                return UnityObjectToClipPos (v);
                //顶点着色器输出：UnityObjectToClipPos (v)————经过MVP变换的顶点坐标；
            }
                //设置顶点着色器结束；（整个顶点阶段相当于请求CPU调用相关数据，以及对顶点做出修改）；
           
           
            fixed4 frag() : SV_target{
                //SV_target：将用户输出的颜色放至渲染目标（render target）；默认输出至帧渲染；
                return fixed4(1.0,1.0,1.0,1.0);
                //输出一个fixed4类型的变量，其每个分量范围为（0，1）
            }
                //设置片元/像素着色器结束；（整个阶段相当于接收之前顶点着色的结果，再对像素/片元做着色）
            
            ENDCG
        }
    }
}