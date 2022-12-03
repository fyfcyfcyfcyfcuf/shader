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
            float3 worldnormal : TEXCOORD0;
            float3 worldPos : TEXCOORD1; 

        };

        v2f vert(a2v v) {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);
            //将顶点由模型坐标转换成世界坐标

            o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
            //将模型顶点坐标并转换成世界坐标

            o. worldnormal = normalize(mul(v.normal, (float3x3)unity_WorldToObject));
            //模型法线转换成世界法线并通过normalize函数归一化；

            return o ;
            }

            fixed4 frag(v2f i) : SV_TARGET{
               
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                //获取环境光
                fixed3 wroldnormal = normalize(i.worldnormal);
                //法线归一化
                fixed3 WorldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                //光照方向归一化
                fixed3 diffuse = _Diffuse.rgb * _LightColor0.rgb *saturate( dot(WorldLightDir,wroldnormal) );

                fixed3 reflectDir = normalize(reflect(-WorldLightDir, wroldnormal));
                //获取反射方向
                fixed3 ViewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                //获取视角方向
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(reflectDir, ViewDir)),_Gloss);
                //计算高光
                return fixed4 (diffuse + specular + ambient,1.0);

                //return i;
            }

            ENDCG
            }
        }
            Fallback"Specular"
    }
            
