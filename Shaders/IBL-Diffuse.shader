Shader "MSLG/IBL/Diffuse"
{
	Properties
	{
		_MainTex("Albedo Texture", 2D) = "white" {}
		[NoScaleOffset]
		_NormalTex("Normal Texture", 2D) = "bump" {}
        _IBLTexCube("IBL Cubemap", Cube) = "black" {}
	}

	SubShader
	{
		Pass
		{
			Tags{ "LightMode" = "ForwardBase" }

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
            
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
				half3 wNormal : TEXCOORD1;
				half3 wTangent : TEXCOORD2;
				half3 wBitangent : TEXCOORD3;
			};

			sampler2D _MainTex;
			half4 _MainTex_ST;
			sampler2D _NormalTex;
            samplerCUBE _IBLTexCube;

			v2f vert(appdata v)
			{
				v2f o;

				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.wNormal = UnityObjectToWorldNormal(v.normal);
				o.wTangent = UnityObjectToWorldNormal(v.tangent.xyz);
				o.wBitangent = cross(o.wNormal, o.wTangent) * v.tangent.w * unity_WorldTransformParams.w;

				return o;
			}
            
            #define DIFFUSE_MIP_LEVEL 5

            half3 SampleTexCube(samplerCUBE cube, half3 normal, half mip)
            {
                return texCUBElod(cube, half4(normal, mip));
            }
            
			fixed4 frag(v2f i) : SV_Target
			{
				half3 albedoColor = tex2D(_MainTex, i.uv);
				half3 normalTex = tex2D(_NormalTex, i.uv) * 2 - 1;	
                
				half3 N = normalize(i.wTangent * normalTex.r + i.wBitangent * normalTex.g + i.wNormal * normalTex.b);
                
                half3 indirectDiffuse = SampleTexCube(_IBLTexCube, N, DIFFUSE_MIP_LEVEL);
                half3 diffuse = albedoColor * indirectDiffuse;
                
                half4 color = 0;
                color.rgb = diffuse;
                
				return color;
			}
			ENDCG
		}
	}
}