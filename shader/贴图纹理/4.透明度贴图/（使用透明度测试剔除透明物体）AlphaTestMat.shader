// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Unity Shader Boook/Chaper 8/Alpha Test"
{
    Properties
    {
        _Color ("Main Tint", Color)= (1,1,1,1)
        _MainTex ("Main Texst", 2D) = "white"{}
        _Cutoff ("Alpha Cutoff", Range(0, 1)) = 0.5
        //Cutoff用于控制透明度测试的判断条件。范围是[0， 1]——纹理的透明度范围就是（0，1）；
    }
        SubShader
        {
            Tags{ "Queue" = "AlphaTest" "IgnoreProjector" = "True" "RenderType" = "TransprentCutout"}
            //将Queue的标签设置为Alpha Test；
            //RenderType可以将Shader归入到提前定义的组————（此处定义至TransprentCutout中），指明该Shader使用了透明度测试
            //将IgnoreProjector设置为True意味着该Shader不会受投影器（Propertise）影响

            //通常使用透明度测试都需要声明以上标签


            pass
            {
                Tags{ "LightMode" = "ForwardBase"}

                CGPROGRAM

                #pragma vertex vert
                #pragma fragment frag 

                #include "Lighting.cginc"

                fixed4 _Color;
                sampler2D _MainTex;
                float4 _MainTex_ST;
                fixed _Cutoff;

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

                    clip(texColor.a - _Cutoff);
                    //该函数表示只要texcolor，小于cutoff就舍弃该片元；
                    

                    fixed3 albedo = texColor.rgb * _Color.rgb;
                    fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                    fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(worldNormal, worldLightDir));
                    
                    return fixed4(ambient + diffuse, 1.0);
                    
                }

                ENDCG
            }
        }
    
    Fallback "Transparent/Cutout/VertexLit"
    //此次fallback可以保证subshader无法工作时；有合适的替代shader；
    //同时可以保证使用透明度测试的物体可以正确的向其它物体投射阴影；
}