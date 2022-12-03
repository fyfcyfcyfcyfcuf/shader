Shader "Unity Shader Boook/Chaper 8/Alpha Blend"
{
    Properties
    {
        _Color ("Main Tint", Color)= (1,1,1,1)
        _MainTex ("Main Tex", 2D) = "white"{}
        _AphaScale("Alpha Scale",range(0,1)) = 1
        //_AphaScale用于在透明纹理的基础上。控制整体的透明度；
    }
        SubShader
        {
            Tags{ "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transprent"}
            //将Queue的标签设置为Transparent队列；
            //RenderType可以将Shader归入到提前定义的组————（此处定义至Transparent中），指明该Shader使用了透明度混合；
            //将IgnoreProjector设置为True意味着该Shader不会受投影器（Projectors）影响;

            //通常使用透明度混合都需要声明以上标签



            //——————————————————————第一个pass只渲染背面；
            pass
            {
                Tags{ "LightMode" = "ForwardBase"}
                //使unity按前向渲染路径的方式提供正确的光照变量

                Cull Front
                //只渲染背面

                ZWrite Off
                //关闭深度写入
                Blend SrcAlpha OneMinusSrcAlpha
                //设置混合因子：源颜色为SrcAlpha；目标颜色为OneMinueSrcAlpha

                CGPROGRAM

                #pragma vertex vert
                #pragma fragment frag 

                #include "Lighting.cginc"

                fixed4 _Color;
                sampler2D _MainTex;
                float4 _MainTex_ST;
                fixed _AphaScale;

                struct a2v {
                    float4 vertex : POSITION;
                    float3 normal : NORMAL;
                    float4 texcoord : TEXCOORD0;
                };

                struct v2f{

                    float4 pos : SV_POSITION;
                    float3 worldNormal :TEXCOORD0;
                    float3 worldPos : TEXCOORD1;
                    float2 uv : TEXCOORD2;

                };


                v2f vert(a2v v){
                    v2f o;
                    o.pos = UnityObjectToClipPos(v.vertex);
                    o.worldNormal = UnityObjectToWorldNormal(v.normal);

                    o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                    o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

                    return o;
                }

                fixed4 frag(v2f i) : SV_TARGET{
                    fixed3 worldNormal = normalize(i.worldNormal);

                    fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

                    fixed4 texColor = tex2D(_MainTex, i.uv);

                    fixed3 albedo = texColor.rgb * _Color.rgb;

                    fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                    fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(worldNormal, worldLightDir));
                    
                    return fixed4(ambient + diffuse, texColor.a * _AphaScale);
                    //将输出中的透明通道由1改为————贴图透明通道与材质参数_AphaScale的乘积
                    //注意：必须要使用Blend命令打开混合，否则该透明度输出不会有任何影响；
                    
                }

                ENDCG
            }


            //——————————————————————第二个pass只渲染正面；
             pass
            {
                Tags{ "LightMode" = "ForwardBase"}
                //使unity按前向渲染路径的方式提供正确的光照变量

                Cull Back

                ZWrite Off
                //关闭深度写入
                Blend SrcAlpha OneMinusSrcAlpha
                //设置混合因子：源颜色为SrcAlpha；目标颜色为OneMinueSrcAlpha

                CGPROGRAM

                #pragma vertex vert
                #pragma fragment frag 

                #include "Lighting.cginc"

                fixed4 _Color;
                sampler2D _MainTex;
                float4 _MainTex_ST;
                fixed _AphaScale;

                struct a2v {
                    float4 vertex : POSITION;
                    float3 normal : NORMAL;
                    float4 texcoord : TEXCOORD0;
                };

                struct v2f{

                    float4 pos : SV_POSITION;
                    float3 worldNormal :TEXCOORD0;
                    float3 worldPos : TEXCOORD1;
                    float2 uv : TEXCOORD2;

                };


                v2f vert(a2v v){
                    v2f o;
                    o.pos = UnityObjectToClipPos(v.vertex);
                    o.worldNormal = UnityObjectToWorldNormal(v.normal);

                    o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                    o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

                    return o;
                }

                fixed4 frag(v2f i) : SV_TARGET{
                    fixed3 worldNormal = normalize(i.worldNormal);

                    fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

                    fixed4 texColor = tex2D(_MainTex, i.uv);

                    fixed3 albedo = texColor.rgb * _Color.rgb;

                    fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                    fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(worldNormal, worldLightDir));
                    
                    return fixed4(ambient + diffuse, texColor.a * _AphaScale);
                    //将输出中的透明通道由1改为————贴图透明通道与材质参数_AphaScale的乘积
                    //注意：必须要使用Blend命令打开混合，否则该透明度输出不会有任何影响；
                    
                }

                ENDCG
            }
        }
    
    Fallback "Transparent/Cutout/VertexLit"
    //此次fallback可以保证subshader无法工作时；有合适的替代shader；
    //同时可以保证使用透明度测试的物体可以正确的向其它物体投射阴影；
}