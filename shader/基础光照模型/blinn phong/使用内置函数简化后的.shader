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

            o. worldnormal = normalize(UnityObjectToWorldNormal(v.normal));
            //模型法线(UnityObjectToWorldNormal函数，输入模型空间中的顶点坐标来获取)

            return o ;
            }

            fixed4 frag(v2f i) : SV_TARGET{
               
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                //获取环境光
                fixed3 wroldnormal = normalize(i.worldnormal);
                //法线归一化
                fixed3 WorldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                //光照方向(通过UnityWorldSpaceLightDir函数，输入顶点坐标来获取)
                fixed3 diffuse = _Diffuse.rgb * _LightColor0.rgb *saturate( dot(WorldLightDir,wroldnormal) );
                //计算漫反射
                
                fixed3 ViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                //获取视角方向(通过UnityWorldSpaceViewDir函数，输入顶点坐标来获取)
                fixed3 halfDir = normalize(WorldLightDir + ViewDir);
               //计算半程向量
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(halfDir, wroldnormal)),_Gloss);
                //计算高光
                return fixed4 (diffuse + specular + ambient,1.0);

                //return i;
            }

            ENDCG
            }
        }
            Fallback"Specular"
    }
            
