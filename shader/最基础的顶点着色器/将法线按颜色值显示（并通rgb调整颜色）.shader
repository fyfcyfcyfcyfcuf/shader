// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

shader"Unity Shaders Book/Chapter 5/MY Shader1"{
    Properties{
        _color ("color tint",Color) = (1.0,1.0,1.0,1.0)
        //color tint表示用色轮控制颜色
    }
    subshader {
        pass{
            CGPROGRAM

            #pragma vertex vert
            //将顶点着色器的函数定义为 vert（基本格式为：#pragma vertex/fragment name）；
            #pragma fragment frag
            //将片元着色器的函数定义为 frag；

            fixed4 _color;
            //定义一个于属性名称和类型都与属性（properties）中匹配的变量
           
           //————————————————声明区

           struct a2v{
            //使用结构体a2v来获得cpu数据的输入，以及赋值给相关函数

            float4 vertex : POSITION;
            //将模型顶点坐标传递给‘vertex’储存
            float3 normal : NORMAL;
            //将模型法线方向传递给‘normal’储存
            float4 texcoord : TEXCOORD0;
            //将模型的第一套传递给‘texcoord’储存
           };

            //————————————————结构体1：a2v——此时该结构体用于向cpu申请数据

           struct v2f{
            //使用此结构体定义顶点着色器的输出
            
            float4 pos : SV_POSITION;
            //将裁剪空间中的顶点位置，传给pos函数储存
            
            fixed3 color : COLOR0;
            //将颜色信息传给color函数储存
           };
           
            //——————————————————结构体2：a2f——此时该结构体用于顶点着色器的数据传出，以及片元着色器的数据的传入

            v2f vert(a2v v) 
            {
                v2f o;
                //声明结构体v2f在顶点着色器中为o
                
                o.pos = UnityObjectToClipPos(v.vertex);
                //o其中的的pos=经过mvp变换的顶点坐标
                
                o.color = v.normal * 0.5 + fixed3(0.5,0.5,0.5);
                //将法线值转换成颜色值
                //因为法向各分量范围是（-1，1），为使其转换至颜色范围的（0，1）而进行运算
                
                return o;

                
            }
                
            //————————————————————顶点着色器
           
            fixed4 frag(v2f i) : SV_target
            //将结构体v2f传入并赋给i函数（由于片元着色器为逐片元操作的，而传进的数据是逐顶点的所以在使用前进行了插值）
            {
                fixed3 c = i.color;
                //定义i.color为fixed3类型的函数
                c*=_color.rgb;
                //使用_color属性控制输出颜色

                return fixed4(c,1.0);
                
            }
            //————————————————————片元着色器
            ENDCG
        }
    }
}