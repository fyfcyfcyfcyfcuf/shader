Shader "Unity Shaders Book/Chapter 7/Normal Map In Tangent Space"
{
    Properties
    {
        _Color ("Color Tint", Color) = (1, 1, 1, 1)
        _MainTex ("Main Tex", 2D) = "white" {}
        // 法线纹理，"bump"表示默认使用Unity内置的法线纹理
        _BumpMap ("Normal Map", 2D) = "bump" {}
        // 控制凹凸程度，当它为0时，表示该法线纹理不会对光照产生任何影响
        _BumpScale ("Bump Scale", Float) = 1.0
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
                // 切线方向，使用float4类型（不同于法线的float3）
                // 使用tangent.w分量来决定切线空间的第三个坐标轴——副切线的方向性
                float4 tangent : TANGENT;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                // UV使用float4类型，xy存储主纹理坐标，zw存储法线纹理坐标（出于减少差值寄存器的使用数量的目的）
                float4 uv : TEXCOORD0;
                // 变换到切线空间的光照方向
                float3 lightDir : TEXCOORD1;
                // 变换到切线空间的视角方向
                float3 viewDir : TEXCOORD2;
            };


            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                // 存储主纹理的uv值
                o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                // 存储法线纹理的uv值
                o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;

                /*
                // 计算副切线，使用w分量确定副切线的方向性（与法线、切线垂直的有两个方向）
                float3 binormal = cross(normalize(v.normal), normalize(v.tangent.xyz)) * v.tangent.w;
                // 构建一个从模型空间向切线空间转换的矩阵，按照切线（x轴）、副切线（y轴）、法线（z轴）排列即可得到
                float3x3 rotation = float3x3(v.tangent.xyz, binormal, v.normal);
                */
                // 使用内置的宏（在UnityCG.cginc），即可得到变换的矩阵，省去了上面的计算过程，
                // 然后直接调用内置rotation变量就是这个矩阵
                TANGENT_SPACE_ROTATION;

                // 将光照方向由模型空间转到切线空间
                // 使用内置函数ObjSpaceLightDir，得到模型空间下的光照方向
                o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex)).xyz;
                // 将视角方向由模型空间转到切线空间
                // 使用内置函数ObjSpaceViewDir，得到模型空间下的视角方向
                o.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex)).xyz;

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // 归一化切线空间的光照方向
                fixed3 tangentLightDir = normalize(i.lightDir);
                // 归一化切线空间的视角方向
                fixed3 tangentViewDir = normalize(i.viewDir);

                // 对法线纹理进行采样
                fixed4 packedNormal = tex2D(_BumpMap, i.uv.zw);
                fixed3 tangentNormal;
                // 如果纹理没有被标记为“Normal map”，则手动反映射得到法线方向
                // tangentNormal.xy = (packedNormal.xy * 2 - 1);
                // 如果纹理被标记为“Normal map”，Unity就会根据不同的平台来选择不同的压缩方法，需要调用UnpackNormal来进行反映射，
                // 如果这时再手动计算反映射就会出错，因为_BumpMap的rgb分量不再是切线空间下的法线方向xyz值了
                tangentNormal = UnpackNormal(packedNormal);
                tangentNormal.xy *= _BumpScale;
                // 因为最终计算是得到归一化的法线，所以利用三维勾股定理得到z分量
                // 因为使用的是切线空间下的法线纹理，所以可以保证z分量为正
                tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));

                fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(tangentNormal, tangentLightDir));

                fixed3 halfDir = normalize(tangentLightDir + tangentViewDir);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(tangentNormal, halfDir)), _Gloss);

                return fixed4(ambient + diffuse + specular, 1.0);
            }
            ENDCG
        }
    }

    // 用内置的Specular Shader兜底
    Fallback "Specular"
}