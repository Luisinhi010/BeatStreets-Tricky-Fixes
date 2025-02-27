package;

import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.FlxSprite;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.math.FlxPoint;
import flixel.FlxG;

/**
 * FlxSprite that creates volumetric cloud effects using shaders.
 * Supports different cloud types, custom colors, and density control.
 * 
 * Basic example:
 * ```haxe
 * // Basic white cloud
 * var cloud = new VolumetricCloudSprite(100, 100);
 * cloud.makeGraphic(300, 300, 0x00FFFFFF);
 * cloud.setColors(0xFFDCDCDC, 0xFFFFFFFF);
 * add(cloud);
 * 
 * // Bluish mist with blend mode
 * var mist = new VolumetricCloudSprite(0, 0);
 * mist.makeGraphic(FlxG.width, FlxG.height, 0x00FFFFFF);
 * mist.cloudType = MIST;
 * mist.setColors(0xFFB0C4DE, 0xFFE6E6FA);
 * mist.blend = ADD;
 * add(mist);
 * 
 * // Dark storm cloud
 * var storm = new VolumetricCloudSprite(200, 50);
 * storm.makeGraphic(500, 400, 0x00FFFFFF);
 * storm.cloudType = STORM;
 * storm.setColors(0xFF4A4A4A, 0xFF808080);
 * storm.speed = 2.0;
 * add(storm);
 * ```
 */
class VolumetricCloudSprite extends FlxSprite
{
    /** The shader responsible for the cloud effect. */
    public var cloudShader(default, null):VolumetricCloudShader;
    
    /** Accumulated time for animation. */
    public var time:Float = 0;
    
    /** Cloud animation speed. */
    public var speed:Float = 1.0;
    
    /** Cloud density (0.0 to 2.0). */
    @:range(0, 2) public var density:Float = 1.0;
    
    /** Light direction affecting the cloud. */
    public var lightDirection:FlxPoint;
    
    /** Cloud type (MIST, NORMAL, STORM). */
    public var cloudType(default, set):CloudType = NORMAL;
    
    /** Base cloud color. */
    public var baseColor:FlxColor = 0xFFFFFFFF;
    
    /** Highlight cloud color. */
    public var highlightColor:FlxColor = 0xFFFFFFFF;

    // Cache for optimization
    private var _lastDensity:Float = -1;
    private var _lastBaseColor:FlxColor = 0;
    private var _lastHighlightColor:FlxColor = 0;
    private var _lastLightDir:FlxPoint = FlxPoint.get();
    private var _cached:Bool = false;

    /**
     * Creates a new volumetric cloud.
     * @param X Initial X position.
     * @param Y Initial Y position.
     */
    public function new(?X:Float = 0, ?Y:Float = 0)
    {
        super(X, Y);
        
        if (FlxG.save.data.lowend) {
            // Fallback for low-end devices
            makeGraphic(1, 1, 0x44FFFFFF);
            return;
        }

        initCloud();
    }

    private function initCloud():Void 
    {
        cloudShader = new VolumetricCloudShader();
        shader = cloudShader;
        lightDirection = FlxPoint.get(1.0, -1.0).normalize();
        
        makeGraphic(1, 1, 0xFFFFFFFF);
        
        cloudShader.uTime.value = [0.0];
        cloudShader.uResolution.value = [width, height];
        cloudShader.uDensity.value = [density];
        cloudShader.uLightDir.value = [lightDirection.x, lightDirection.y];
        updateCloudParameters();
    }

    public function set_cloudType(value:CloudType):CloudType {
        if (cloudType == value) return value;
        cloudType = value;
        updateCloudParameters();
        return value;
    }
    
    /**
     * Updates parameters based on the cloud type.
     */
    private function updateCloudParameters() {
        if (cloudShader == null) return;
        
        switch(cloudType) {
            case MIST:
                density = 0.3;
                speed = 0.2;
                cloudShader.uNoiseScale.value = [3.0];
                cloudShader.uNoiseOctaves.value = [2];
            case NORMAL:
                density = 1.0;
                speed = 1.0;
                cloudShader.uNoiseScale.value = [2.0];
                cloudShader.uNoiseOctaves.value = [4];
            case STORM:
                density = 1.5;
                speed = 1.8;
                cloudShader.uNoiseScale.value = [1.5];
                cloudShader.uNoiseOctaves.value = [5];
        }
    }

    /**
     * Sets the cloud colors.
     * @param base Base cloud color
     * @param highlight Highlight color when illuminated
     */
    public function setColors(base:FlxColor, highlight:FlxColor) {
        if (cloudShader == null) return;
        
        baseColor = base;
        highlightColor = highlight;
        _cached = false;
    }

    override public function update(elapsed:Float):Void
    {
        if (cloudShader == null) {
            super.update(elapsed);
            return;
        }

        time += elapsed * speed;
        cloudShader.uTime.value = [time];

        // Update shaders only when necessary
        if (!_cached || _lastDensity != density || 
            _lastBaseColor != baseColor || 
            _lastHighlightColor != highlightColor ||
            !_lastLightDir.equals(lightDirection))
        {
            updateShaderValues();
        }

        super.update(elapsed);
    }

    private function updateShaderValues():Void 
    {
        if (cloudShader == null) return;

        cloudShader.uResolution.value = [width, height];
        cloudShader.uDensity.value = [density];
        cloudShader.uLightDir.value = [lightDirection.x, lightDirection.y];
        
        var baseVec = [baseColor.redFloat, baseColor.greenFloat, baseColor.blueFloat];
        var highlightVec = [highlightColor.redFloat, highlightColor.greenFloat, highlightColor.blueFloat];
        cloudShader.uBaseColor.value = baseVec;
        cloudShader.uHighlightColor.value = highlightVec;

        // Update cache
        _lastDensity = density;
        _lastBaseColor = baseColor;
        _lastHighlightColor = highlightColor;
        _lastLightDir.copyFrom(lightDirection);
        _cached = true;
    }

    override public function destroy():Void
    {
        cloudShader = null;
        shader = null;
        _lastLightDir = FlxDestroyUtil.put(_lastLightDir);
        lightDirection = FlxDestroyUtil.put(lightDirection);
        super.destroy();
    }
}

enum CloudType {
    MIST;   // Light mist
    NORMAL; // Regular cloud
    STORM;  // Storm cloud
}

/**
 * Shader responsible for the volumetric cloud effect.
 * Implements 3D noise and custom lighting.
 */
class VolumetricCloudShader extends FlxFixedShader
{
    @:glFragmentSource('
        #pragma header

        uniform float uTime;
        uniform vec2 uResolution;
        uniform float uDensity;
        uniform vec2 uLightDir;
        uniform vec3 uBaseColor;
        uniform vec3 uHighlightColor;
        uniform float uNoiseScale;
        uniform int uNoiseOctaves;

        vec4 permute(vec4 x){return mod(((x*34.0)+1.0)*x, 289.0);}
        vec4 taylorInvSqrt(vec4 r){return 1.79284291400159 - 0.85373472095314 * r;}

        float snoise(vec3 v){ 
            const vec2  C = vec2(1.0/6.0, 1.0/3.0);
            const vec4  D = vec4(0.0, 0.5, 1.0, 2.0);

            vec3 i  = floor(v + dot(v, C.yyy));
            vec3 x0 =   v - i + dot(i, C.xxx);

            vec3 g = step(x0.yzx, x0.xyz);
            vec3 l = 1.0 - g;
            vec3 i1 = min(g.xyz, l.zxy);
            vec3 i2 = max(g.xyz, l.zxy);

            vec3 x1 = x0 - i1 + C.xxx;
            vec3 x2 = x0 - i2 + C.yyy;
            vec3 x3 = x0 - D.yyy;

            i = mod(i, 289.0);
            vec4 p = permute(permute(permute( 
                    i.z + vec4(0.0, i1.z, i2.z, 1.0))
                    + i.y + vec4(0.0, i1.y, i2.y, 1.0)) 
                    + i.x + vec4(0.0, i1.x, i2.x, 1.0));

            float n_ = 0.142857142857;
            vec3  ns = n_ * D.wyz - D.xzx;

            vec4 j = p - 49.0 * floor(p * ns.z * ns.z);

            vec4 x_ = floor(j * ns.z);
            vec4 y_ = floor(j - 7.0 * x_);

            vec4 x = x_ *ns.x + ns.yyyy;
            vec4 y = y_ *ns.x + ns.yyyy;
            vec4 h = 1.0 - abs(x) - abs(y);

            vec4 b0 = vec4(x.xy, y.xy);
            vec4 b1 = vec4(x.zw, y.zw);

            vec4 s0 = floor(b0)*2.0 + 1.0;
            vec4 s1 = floor(b1)*2.0 + 1.0;
            vec4 sh = -step(h, vec4(0.0));

            vec4 a0 = b0.xzyw + s0.xzyw*sh.xxyy;
            vec4 a1 = b1.xzyw + s1.xzyw*sh.zzww;

            vec3 p0 = vec3(a0.xy, h.x);
            vec3 p1 = vec3(a0.zw, h.y);
            vec3 p2 = vec3(a1.xy, h.z);
            vec3 p3 = vec3(a1.zw, h.w);

            vec4 norm = taylorInvSqrt(vec4(dot(p0,p0), dot(p1,p1), dot(p2,p2), dot(p3,p3)));
            p0 *= norm.x;
            p1 *= norm.y;
            p2 *= norm.z;
            p3 *= norm.w;

            vec4 m = max(0.6 - vec4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
            m = m * m;
            return 42.0 * dot(m*m, vec4(dot(p0,x0), dot(p1,x1), dot(p2,x2), dot(p3,x3)));
        }

        float fbm(vec3 p) {
            float sum = 0.0;
            float amp = 1.0;
            float freq = uNoiseScale;
            
            for(int i = 0; i < 6; i++) {
                if(i >= uNoiseOctaves) break;
                sum += amp * snoise(p * freq);
                amp *= 0.5;
                freq *= 2.0;
            }
            return sum;
        }

        void main() {
            vec2 uv = openfl_TextureCoordv;
            vec2 pos = uv * 2.0 - 1.0;
            pos.x *= uResolution.x/uResolution.y;
            
            float noise = fbm(vec3(pos * 2.0, uTime * 0.2));
            noise = pow(noise * 0.5 + 0.5, 1.5);
            
            float cloud = smoothstep(0.4, 0.6, noise) * uDensity;
            
            // Lighting with custom colors
            float lightInfluence = dot(normalize(vec3(uLightDir, 0.3)), vec3(pos, 1.0));
            vec3 cloudColor = mix(uBaseColor, uHighlightColor, lightInfluence * 0.5);
            
            gl_FragColor = vec4(cloudColor * cloud, cloud);
        }
    ')

    public function new()
    {
        super();
        uNoiseScale.value = [2.0];
        uNoiseOctaves.value = [4];
        uBaseColor.value = [0.8, 0.8, 0.9];
        uHighlightColor.value = [1.0, 1.0, 1.0];
    }
}
