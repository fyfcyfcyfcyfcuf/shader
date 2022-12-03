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
            // 设置为ForwardBase，处理环境光和第一个逐像素光照（平行光）

            CGPROGRAM

            #pragma multi_compile_fwdbase
            //使用编译指令，使Base Pass的光照衰减等光照变量能被正确赋值；

            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"

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
                fixed3 worldNormal = normalize(i.worldNormal);
                
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                // Unity会选择最亮的平行光传递给Base Pass进行逐像素处理
                // 其他平行光会按照逐顶点或在Additional Pass中按逐像素的方式处理
                // 对于Base Pass来说，处理逐像素光源类型一定是平行光
                // 使用_WorldSpaceLightPos0得到这个平行光的方向

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                //环境光照只计算一次，所以在base pass计算
                //与之类似，还有自发光（本例中物体不自发光所以无代码）

                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * max(0, dot(worldNormal, worldLightDir));
                // 使用_LightColor0得到平行光的颜色和强度
                // （_LightColor0已经是颜色和强度相乘后的结果）

                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                fixed3 halfDir = normalize(worldLightDir + viewDir);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);

                fixed atten = 1.0;
                // 因为平行光没有衰减，所以衰减值为1.0

                return fixed4(ambient + (diffuse + specular) * atten, 1.0);
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