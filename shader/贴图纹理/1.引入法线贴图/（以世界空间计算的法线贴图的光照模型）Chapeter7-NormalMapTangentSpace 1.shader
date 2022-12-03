// 修改Shader命名
Shader "Unity Shaders Book/Chapter 7/Normal Map In World Space"
{
    Properties
    {
        _Color ("Color Tint", Color) = (1, 1, 1, 1)
        _MainTex ("Main Tex", 2D) = "white" {}
        _BumpMap ("Normal Map", 2D) = "bump" {}
        //法线的变量使用bump（对应模型自身法线）作为默认值
        _BumpScale ("Bump Scale", Float) = 1.0
        //用于控制凹凸程度
        _Specular ("Specular", Color) = (1, 1, 1, 1)
        _Gloss ("Gloss", Range(8.0, 256)) = 20
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

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            float _BumpScale;
            fixed4 _Specular;
            float _Gloss;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                //切线方向，使用float类型
                //因为需要多一个w分量来确定切线空间的第三个坐标的正负；
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 uv : TEXCOORD0;
                //uv的xy储存纹理坐标；uv的zw分量储存法线纹理坐标（节省寄存器）
                float4 TtoW0 : TEXCOORD1;
                float4 TtoW1 : TEXCOORD2;
                float4 TtoW2 : TEXCOORD3;
                //以上为包含一个3x3的变换矩阵，用以记录切线空间转换至世界空间的矩阵
                //为了充分利用插值寄存器,将该3x4矩阵的w分量用以储存世界空间下的顶点坐标
            };


            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                //用uv的xy储存贴图信息，并在此定义缩放和偏移
                o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;
                //用uv的zw储存法线贴图信息，并在此定义缩放和偏移


                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                //模型顶点转换至世界坐标
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
                //模型法线转换至世界坐标
                fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
                //模型切线转换至世界坐标
                fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;

                /* 计算切线空间到世界空间的矩阵，并存储到TtoWX变量中 */
                // 将切线、副切线、法线按列拜访，
                // 得到从切线空间到世界空间的变换矩阵
                // w分量用来存储顶点在世界空间下的坐标
                o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
                o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
                o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);
                //切线空间：每一个顶点为原点x轴为切线，z轴为法线，而y轴为副法线（副切线）
                //通常该副法线由法线与切线叉乘得出
               
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
       
                float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
                //拆出矩阵的w分量构成世界顶点坐标
                fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
                //归一化灯光方向
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));
                //归一化观察方向
                
                fixed3 bump = UnpackNormal(tex2D(_BumpMap, i.uv.zw));
                //采样并反映射得到法线信息
                //将法线纹理（0，1）的范围，反映射至（-1，1）模型法线坐标（详见下长文）
                bump.xy *= _BumpScale;
                //缩放法线贴图的xy
                bump.z = sqrt(1.0 - saturate(dot(bump.xy, bump.xy)));
                //利已缩放过的xy值，以三维勾股定理求出影响后的z轴
                bump = normalize(half3(dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));
                //将得到的法线由切线空间转换至世界空间


                /*
                如果在贴图类型中没有将贴图定义成法线贴图（normal map），就需要手动反映射得到法线方向
                tangentNormal.xy = (packedNormal.yz*2 -1)————（见模型纹理笔记）;

                如果贴图已经被标记为法线贴图，unity就会根据不同平台来选择压缩方法
                此时再手动计算反映射就会出错，因为_BumpMap的rgb分量不再是切线空间下的法相方向xyz值了
                此时则需要调用unpacknormal来进行反映射；
                */



                fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;
                //使用tex2d函数将纹理映射至uv再混合颜色
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                //环境光
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(bump, lightDir));
                //漫反射模型
                fixed3 halfDir = normalize(lightDir + viewDir);
                //半程向量
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(bump, halfDir)), _Gloss);
                //高光模型
                return fixed4(ambient + diffuse + specular, 1.0);
            }
            ENDCG
        }
    }

    // 用内置的Specular Shader兜底
    Fallback "Specular"
}