// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unityshader Book/Chapter 6/Blinn Phong Inner Func"{
Properties{
    _Diffuse ("Diffuse", Color) = (1,1,1,1)
    //漫反射颜色
    _Specular ("Specular", Color) = (1,1,1,1)
    //控制高光反射颜色
    _Gloss ("Gloss", Range(8.0, 256)) = 20
    //控制高光范围
    }
SubShader{
    pass{
        Tags{"LightMode" = "ForwardBase"}
        CGPROGRAM
// Upgrade NOTE: excluded shader from DX11; has structs without semantics (struct v2f members pos,Color)
        #pragma vertex vert 
        #pragma fragment frag 
        #include "Lighting.cginc"

        fixed4 _Diffuse;
        fixed4 _Specular;
        float _Gloss;

        struct a2v{
            float4 vertex : POSITION;
            float3 normal : NORMAL;
        };

        struct v2f{
            float4 pos : SV_POSITION;
            fixed3 color : COLOR;

        };

        v2f vert(a2v v) {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);
            
            
            fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
            //环境光；

            fixed3 WorldNormal = normalize(mul(v.normal, (float3x3)unity_WorldToObject));
            //模型法线转换成世界法线并通过normalize函数归一化；

            fixed3 WorldLightDir = normalize(_WorldSpaceLightPos0.xyz);
            //获取世界灯光位置，并通过normalize函数归一化；

            fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(WorldLightDir,WorldNormal));
            //使用兰伯特光照模型 ：漫反射模型 = 灯光强度和颜色 * 漫反射颜色 * 灯光和法线点乘；

            fixed3 reflectDir = normalize(reflect(-WorldLightDir,WorldNormal));
            //输入光照方向和法线方向，就可以通过reflect函数获得反射方向；
            //但是CG中要求光照方向必须有灯光指向交点所以灯光要取倒；

            fixed3 ViewDir = normalize(_WorldSpaceCameraPos.xyz-mul(unity_ObjectToWorld, v.vertex).xyz);
            //获取摄像机指向顶点的矢量；

            fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(reflectDir,ViewDir)),_Gloss);
            //高光 = 灯光强度和颜色 * 高光颜色 * 以Gloss做指数的（归一化的（反射射光与摄像机方向的点乘））；

            o.color = ambient + diffuse + specular;
            //总光照模型o = 环境光 + 漫反射+ 高光

            return o ;
            }

            fixed4 frag(v2f i) : SV_TARGET{

                return fixed4(i.color,1.0);
            }

            ENDCG
            }
        }
            Fallback"Specular"
    }
            
