shader "Unity Shader Book/Chaper 7/Ramp TextureMat"
{
    Properties
    {
        _Color ("Color Tint", Color) = (1,1,1,1)
        _RampTex ("Ramp Tex", 2D) = "white"{}
        //输入ramp贴图
        _Specular ("specular", Color) = (1,1,1,1)
        _Gloss ("Gloss", Range(8.0, 256)) = 20
    }


    SubShader
    {
        pass
        {
            Tags{"LightModel" = "ForwardBase"}

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"

            fixed4 _Color;
            sampler2D _RampTex;
            float4 _RampTex_ST;
            //定义ramp属性（缩放，偏移）
            fixed4 _Specular;
            float _Gloss;

            struct a2v{
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
            };

            struct f2v{
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float2 uv : TEXCOORD2;
            };

            f2v vert (a2v v){
                f2v o;
                o.pos = UnityObjectToClipPos(v.vertex);
                //转换并归一化模型顶点至世界空间
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                //转换模型法线至世界空间
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                //转换模型顶点坐标至世界空间
                o.uv = TRANSFORM_TEX(v.texcoord, _RampTex);
                //TRANSFORM_TEX宏用于计算平铺和偏移后的纹理坐标；
                return o;
            }

            fixed4 frag(f2v i) : SV_TARGET{
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                //利用函数UnityWorldSpaceLightDir输入世界顶点坐标获取灯光矢量
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                //利用函数UNITY_LIGHTMODEL_AMBIENT环境光颜色和强度
                fixed halfLambert = 0.5 * dot(worldNormal,worldLightDir) + 0.5;
                //计算半兰伯特
                fixed3 diffuseColor = tex2D(_RampTex, fixed2(halfLambert,halfLambert)).rgb * _Color.rgb;
                //使用半兰伯特构建纹理坐标，并使用该纹理坐标对ramp贴图采样
                //由于贴图没有纵轴所以，UV都使用halfLambert
                //最后再与材质颜色点乘
                fixed3 diffuse = _LightColor0.rgb * diffuseColor;
                //计算漫反射
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                //计算视角向量
                fixed3 halfDir = normalize(worldLightDir + viewDir);
                //计算半程向量
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(halfDir,worldNormal)), _Gloss);
                //计算高光
                return fixed4(ambient + diffuse + specular, 1.0);
                
            }
            ENDCG
        }
    }
    Fallback "Specular"
}