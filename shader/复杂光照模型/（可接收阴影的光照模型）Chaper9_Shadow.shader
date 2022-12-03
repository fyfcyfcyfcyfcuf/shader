// 修改Shader命名
Shader "Unity Shaders Book/Chapter 9/Forward Rendering"
{
    Properties
    {
        _Diffuse("Diffuse", Color) = (1, 1, 1, 1)
        _Specular("Specular", Color) = (1, 1, 1, 1)
        _Gloss("Gloss", Range(8.0, 256)) = 20
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" }

        //Base pass
        Pass
        //定义第一个base pass
        {
            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM

            #pragma multi_compile_fwdbase

            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            //添加新内置文件，新增使用的宏都是在该文件中声明的；


            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                SHADOW_COORDS(2)
                //新增内置宏：用于声明一个用于阴影纹理采样的坐标；
                //因为TEXCOORD0和TEXCOORD1都被用掉了，所以这里传入“（2）”；
            };

            v2f vert(a2v v)
            {
                v2f o;

                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                
                TRANSFER_SHADOW(o);
                //使用内置宏，计算v2f结构中声明的阴影纹理坐标

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed3 worldNormal = normalize(i.worldNormal);
                
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * max(0, dot(worldNormal, worldLightDir));

                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                fixed3 halfDir = normalize(worldLightDir + viewDir);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);

                fixed atten = 1.0;
                fixed shadow = SHADOW_ATTENUATION(i);
                // 内置宏，计算阴影对物体反射的光的衰减值

                return fixed4(ambient + (diffuse + specular) * atten * shadow, 1.0);
                //将得到的阴影值乘以反光部分，得到阴影的影响效果
            }
            ENDCG
        }

        // Additional pass
        Pass
        {
            Tags { "LightMode" = "ForwardAdd" }
            // 设置为ForwardAdd

            Blend One One
            // 开启混合模式，将帧缓冲中的颜色值和不同光照结果进行叠加
            // （Blend One One并不是唯一，也可以使用其他Blend指令，比如：Blend SrcAlpha One）

            // Additional pass中的顶点、片元着色器代码是根据Base Pass中的代码复制修改得到的
            // 这些修改一般包括：去掉Base Pass中的环境光、自发光、逐顶点光照、SH光照的部分
            CGPROGRAM

            #pragma multi_compile_fwdadd
            // 执行该编译指令，使光照变量赋值正确，以保证Additional Pass中访问到正确的光照变量

            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
            };

            v2f vert(a2v v)
            {
                v2f o;

                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // 去掉Base Pass中环境光

                fixed3 worldNormal = normalize(i.worldNormal);

                // 计算不同光源的方向
                #ifdef USING_DIRECTIONAL_LIGHT
                //如果光源是平行光那么该光源就会被unity底层定义USING_DIRECTIONAL_LIGHT
                //根据不同的光源类型计算光照方向
                    fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                    //当光源是平行光时直接通过_WorldSpaceLightPos0.xyz获取方向
                    
                #else
                    fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos.xyz);
                    // 点光源或聚光灯，_WorldSpaceLightPos0表示世界空间下的光源位置
                    // 需要减去世界空间下的顶点位置才能得到光源方向
                #endif

                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * max(0, dot(worldNormal, worldLightDir));
                // 使用_LightColor0得到光源（可能是平行光、点光源或聚光灯）的颜色和强度

                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                fixed3 halfDir = normalize(worldLightDir + viewDir);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);

                
                #ifdef USING_DIRECTIONAL_LIGHT
                //根据不同光源类型计算衰减
                    fixed atten = 1.0;
                    //平行光没有衰减，定义光照衰减为1.0
                #else
                    float3 lightCoord = mul(unity_WorldToLight, float4(i.worldPos, 1)).xyz;
                    //将片元转化至光源空间

                    fixed atten = tex2D(_LightTexture0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL;
                    //如果是其它光源的话，Unity使用一张“衰减纹理”来记录衰减（Lookup Table, LUT)
                    //只需要对该衰减纹理采样即可得到衰减值
                    //此处将上一步转换的片元的r通道，作为uv进行采样
                #endif

                return fixed4((diffuse + specular) * atten, 1.0);
            }

            ENDCG
        }
    }

    Fallback "Specular"
}