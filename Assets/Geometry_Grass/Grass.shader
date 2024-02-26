Shader "Roystan/Grass"
{
    Properties
    {
		[Header(Shading)]
        _TopColor("Top Color", Color) = (1,1,1,1)
		_BottomColor("Bottom Color", Color) = (1,1,1,1)
		_TranslucentGain("Translucent Gain", Range(0,1)) = 0.5
		_TessellationUniform("Tessellation Uniform", Range(1, 64)) = 1
		_BendRotationRandom("Bend Rotation Random", Range(0, 1)) = 0.2
		[Header(______grassSize______)]
		_BladeWidth("Blade Width", Float) = 0.05
		_BladeWidthRandom("Blade Width Random", Float) = 0.02
		_BladeHeight("Blade Height", Float) = 0.5
		_BladeHeightRandom("Blade Height Random", Float) = 0.3
		_BladeBendFactor("BladeBendFactor", float) = 0.3
		_BladeBendForward("BladeBendForward", float) = 0.3

		[Space(10)] 
		[Toggle] _TowardMap ("_TowardMap ?", Float) = 0
		_GrassTowardMap("Grass Toward Map", 2D) = "white" {}
		[Header(__________Wind_________)]
		_WindDistortionMap("Wind Distortion Map", 2D) = "white" {}
		_WindFrequency("Wind Frequency", Vector) = (0.05, 0.05, 0, 0)
		_WindStrengthFactor("Wind Strength Factor",float) = 0.3
		[Header(___Impact_of_object_movement__)]
		_ImpactRadius("Impact Radius", Float) = 1
		
		

    }

	HLSLINCLUDE
	#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
	#include "../Shaders/CustomTessellation.cginc"
	#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
	#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
	
	#define UNITY_TWO_PI 6.28
	#define UNITY_PI 3.14
	#define BLADE_SEGMENTS 3
	CBUFFER_START(UnityPerMaterial)
	float _BendRotationRandom;
	float _BladeHeight;
	float _BladeHeightRandom;	
	float _BladeWidth;
	float _BladeWidthRandom;
	float _BladeBendFactor;
	float _BladeBendForward;
	

	float4 _PositionMoving;
	float _ImpactRadius;

	
	TEXTURE2D (_WindDistortionMap);			SAMPLER(sampler__WindDistortionMap);
	float4 _WindDistortionMap_ST;
	float2 _WindFrequency;
	float _WindStrengthFactor;

	#pragma shader_feature _TOWARDMAP_ON
	TEXTURE2D (_GrassTowardMap);			SAMPLER(sampler__GrassTowardMap);
	float4 _GrassTowardMap_ST;

	float3 _LightDirection;
	CBUFFER_END
	// Simple noise function, sourced from http://answers.unity.com/answers/624136/view.html
	// Extended discussion on this function can be found at the following link:
	// https://forum.unity.com/threads/am-i-over-complicating-this-random-function.454887/#post-2949326
	// Returns a number in the 0...1 range.
	float rand(float3 co)
	{
		return frac(sin(dot(co.xyz, float3(12.9898, 78.233, 53.539))) * 43758.5453);
	}

	// Construct a rotation matrix that rotates around the provided axis, sourced from:
	// https://gist.github.com/keijiro/ee439d5e7388f3aafc5296005c8c3f33
	float3x3 AngleAxis3x3(float angle, float3 axis)
	{
		float c, s;
		sincos(angle, s, c);

		float t = 1 - c;
		float x = axis.x;
		float y = axis.y;
		float z = axis.z;

		return float3x3(
			t * x * x + c, t * x * y - s * z, t * x * z + s * y,
			t * x * y + s * z, t * y * y + c, t * y * z - s * x,
			t * x * z - s * y, t * y * z + s * x, t * z * z + c
			);
	}
	
	
	struct geometryOutput
	{
		float4 pos : SV_POSITION;
		float3 posWS : TEXCOORD1;
		float2 Bladeuv : TEXCOORD0;
		float3 normalWS : TEXCOORD2;
		
	};
	

	geometryOutput geoVertex(float3 posNew, float2 uv , float3 normalWStri)
	{
		geometryOutput o;
		o.posWS = posNew;
		o.normalWS = normalWStri;
		o.pos = TransformWorldToHClip(o.posWS);
		#if defined (UNITY_PASS_SHADOWCASTER)
			o.pos = TransformWorldToHClip(ApplyShadowBias(o.posWS, o.normalWS, _LightDirection));
		#endif
		o.Bladeuv = uv;
		return o;
	}

	void objectInteraction(inout float3 bladePosWS , float level )
	{
		level = pow(level , 1.5);
		float3 interVec = bladePosWS - _PositionMoving.xyz;
		float3 movingVec = normalize(float3(interVec.x , -0.2 , interVec.z));
		
		bladePosWS += level * movingVec *  _ImpactRadius * smoothstep(0.8,0.3,length(interVec)) ; 
		
		//need to correct

	}


	[maxvertexcount(BLADE_SEGMENTS * 2 + 1)]
	void geo(triangle vertexOutput IN[3] : SV_POSITION, inout TriangleStream<geometryOutput> triStream)
	{
		geometryOutput o;
		
		
		float4 pos = IN[0].vertexPos;
		float3 normalOS = IN[0].normalOS;
		float4 tangent = IN[0].tangent;
		float2 groundUV = IN[0].uv;

		float3 binormal = cross(normalize(normalOS.xyz), normalize(tangent.xyz)) * tangent.w;
		float3x3 TBN = float3x3(normalize(tangent.xyz) , binormal , normalize(normalOS.xyz));

		float height = (rand(pos.zyx) * 2 - 1) * _BladeHeightRandom + _BladeHeight;
		float width = (rand(pos.xzy) * 2 - 1) * _BladeWidthRandom + _BladeWidth;

		float2 Winduv = pos.xz * _WindDistortionMap_ST.xy + _WindDistortionMap_ST.zw + _WindFrequency * _Time.y;
		float3 windVector = SAMPLE_TEXTURE2D_LOD(_WindDistortionMap, sampler__WindDistortionMap, Winduv,0)*2 -1;
		float windStrength = dot(windVector,windVector);

		//Matrix
		#if _TOWARDMAP_ON
			groundUV = groundUV * _GrassTowardMap_ST.xy + _GrassTowardMap_ST.zw;
			float2 GrassTowardVector = SAMPLE_TEXTURE2D_LOD(_GrassTowardMap, sampler__GrassTowardMap, groundUV,0)*2 -1;
			float3 ForwardVector = normalize(float3(GrassTowardVector.x , GrassTowardVector.y ,0));
			float3 UpVector = float3(0,0,1);
			float3 rightVector = normalize(cross(UpVector , ForwardVector));
			float3x3 facingRotationMatrix = float3x3(rightVector, ForwardVector , UpVector);
			
			
		#else 
			float3x3 facingRotationMatrix = AngleAxis3x3(rand(pos) * UNITY_TWO_PI, float3(0, 0, 1));
		#endif
		float3x3 bendRotationMatrix = AngleAxis3x3(rand(pos.zzx) * _BendRotationRandom * UNITY_PI * 0.5 , float3(-1, 0, 0));
		float3x3 windRotationMatrix = AngleAxis3x3(windStrength * _WindStrengthFactor , float3(windVector.xz,0));
		float3x3 transformMatrix = mul(mul(facingRotationMatrix , bendRotationMatrix),windRotationMatrix);
		

		float widthOffset = width/BLADE_SEGMENTS;
		float heightOffset = height/BLADE_SEGMENTS;

		//for blade normal
		float3 posWS;
		float3 posWS1;
		float3 posWS2;
		float2 uv1;
		float2 uv2;
		
		


		posWS1 = TransformObjectToWorld(pos + mul(mul(facingRotationMatrix,float3(width, 0, 0)) , TBN));
		uv1 = float2(1,0);
		
		

		posWS2 = TransformObjectToWorld(pos + mul(mul(facingRotationMatrix,float3(-width, 0, 0)) , TBN));
		uv2 = float2(0,0);
		


		float Forward = rand(pos.yyz) * _BladeBendForward;

		for(float i=1;i<BLADE_SEGMENTS;i++)
		{
			
			float ForwardP = pow(i ,  _BladeBendFactor)* Forward;

			posWS = TransformObjectToWorld(pos + mul(mul(transformMatrix,float3(width - widthOffset * i, ForwardP, i * heightOffset)) , TBN));
			//calculate every triangle nromal
			float3 normalWStri = cross(normalize(posWS1 - posWS), normalize(posWS2 - posWS));
			o = geoVertex(posWS1 , uv1 , normalWStri);
			triStream.Append(o);
			o = geoVertex(posWS2 , uv2 , normalWStri);
			triStream.Append(o);

			posWS1 = posWS;
			uv1 = float2(1 - i * 0.5/BLADE_SEGMENTS,i /BLADE_SEGMENTS);
			objectInteraction(posWS1 , i);
			
			posWS2 = TransformObjectToWorld(pos + mul(mul(transformMatrix,float3(-width + widthOffset * i, ForwardP, i * heightOffset)) , TBN));
			uv2 = float2(i * 0.5/ BLADE_SEGMENTS,i /BLADE_SEGMENTS);
			objectInteraction(posWS2 , i);
			

		}

		posWS = TransformObjectToWorld(pos + mul(mul(transformMatrix,float3(0, pow(BLADE_SEGMENTS ,  _BladeBendFactor)* Forward, height)) , TBN));
		float3 normalWStri = cross(normalize(posWS1 - posWS), normalize(posWS2 - posWS));
		o = geoVertex(posWS1 , uv1 , normalWStri);
		triStream.Append(o);
		o = geoVertex(posWS2 , uv2 , normalWStri);
		triStream.Append(o);

		objectInteraction(posWS , BLADE_SEGMENTS);
		o = geoVertex(posWS , float2(0.5,1) , normalWStri);	
		triStream.Append(o);
	}

	ENDHLSL

    SubShader
    {
		Cull Off

        Pass
        {
			Tags
			{
				"RenderType" = "Opaque"
			}
			
            HLSLPROGRAM
			#define SHADOW_BIAS
            #pragma vertex vert
			#pragma geometry geo
            #pragma fragment frag
			#pragma hull hull
			#pragma domain domain
			#pragma target 4.6


            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN      // URP 主光阴影、联机阴影、屏幕空间阴影
			#pragma multi_compile_fragment _ _SHADOWS_SOFT      // URP 软阴影
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"            //从unity中取得我们的光照
			

			float4 _TopColor;
			float4 _BottomColor;
			float _TranslucentGain;
			

			float4 frag (geometryOutput i , half facing : VFACE) : SV_Target
            {	
				Light light = GetMainLight(TransformWorldToShadowCoord(i.posWS));
				float3 normal = facing > 0 ? i.normalWS : -i.normalWS;
				normal = normalize(normal);
				float4 lightCol = float4(light.color,1) * (light.shadowAttenuation);
				float3 diffuse = (lerp(0.7,1,dot(normal , _LightDirection))) * lightCol.xyz; 
				//0.5*SampleSH(normal).rgb 简易环境光的写法
				float4 FinalColor = float4(lerp(_BottomColor , _TopColor , i.Bladeuv.y).xyz * diffuse +0.1*SampleSH(normal).rgb ,1);
				
				return FinalColor;
	
            }
            ENDHLSL
        }

		Pass
        {
            Name "ShadowCaster"
            Tags
            {
                "LightMode" = "ShadowCaster"
            }

            // -------------------------------------
            // Render State Commands
            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull[_Cull]

            HLSLPROGRAM

            // -------------------------------------
            // Shader Stages
            #pragma vertex vert
			#pragma geometry geo
            #pragma fragment frag
			#pragma hull hull
			#pragma domain domain
			#pragma target 4.6

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
			

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            // -------------------------------------
            // Universal Pipeline keywords

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE

            // This is used during shadow map generation to differentiate between directional and punctual light shadows, as they use different formulas to apply Normal Bias
            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW
			
			
            // -------------------------------------
            // Includes
            
			float4 frag(geometryOutput i):SV_TARGET
			{
				return 0;
			}
            ENDHLSL
        }


    }
}