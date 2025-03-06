function onStartSong() 
	{
		upsideZoom();
	}
		
	function onBeatHit(curBeat:Int)
	{
		if (curBeat % 2 == 0
			&& curBeat % 4 != 0
			&& (curBeat >= 64 && curBeat < 128 
				|| curBeat >= 160 && curBeat < 256 
				|| curBeat >= 288 && curBeat < 352)
			&& !(curBeat >= 92 && curBeat < 96 
				|| curBeat >= 188 && curBeat < 192 
				|| curBeat >= 244 && curBeat < 248 
				|| curBeat >= 252 && curBeat < 256 
				|| curBeat >= 340 && curBeat < 344))
		{
			Game.zoomin();
		}
	
		if (curBeat % 8 == 0 
			&& (curBeat < 64 
				|| curBeat >= 96 && curBeat < 160 
				|| curBeat >= 192 && curBeat < 256 
				|| curBeat >= 288 && curBeat <= 352))
		{
			upsideZoom();
		}
	}
	
	function upsideZoom()
	{
		trace("upsideZoom()");
		Game.ignoreDefaultZoom = true;
		FlxTween.cancelTweensOf(Game.camGame);
	
		// Zoom inicial
		FlxTween.tween(Game.camGame, {zoom: Game.defaultCamZoom + 0.1}, Conductor.beatTime * 2, {
			ease: FlxEase.quadInOut,
			onComplete: function(tween:FlxTween)
			{
				// Retorno do zoom
				FlxTween.tween(Game.camGame, {zoom: Game.defaultCamZoom}, Conductor.beatTime * 2, {
					ease: FlxEase.quartInOut,
					onComplete: function(tween:FlxTween)
					{
						Game.ignoreDefaultZoom = false;
					}
				});
			}
		});
	
		// Efeitos visuais
		Game.pixels(true);
		Game.camGame.filters = [
			new ShaderFilter(Game.distortion.shader),
			new ShaderFilter(Game.blur.shader),
			new ShaderFilter(Game.mosaic.shader)
		];
	
		FlxTween.cancelTweensOf(Game.mosaic);
	
		// Efeito mosaico
		FlxTween.tween(Game.mosaic, {pixelSize: Game.daPixelZoom}, Conductor.beatTime * 2, {
			ease: FlxEase.quadInOut,
			onComplete: function(tween:FlxTween)
			{
				FlxTween.tween(Game.mosaic, {pixelSize: 1}, Conductor.beatTime * 2, {
					ease: FlxEase.quartInOut,
					onComplete: function(tween:FlxTween)
					{
						Game.pixels(FlxG.save.data.lowend);
						Game.mosaic.updateShaderResolution(1);
						Game.camGame.filters = [
							new ShaderFilter(Game.distortion.shader),
							new ShaderFilter(Game.blur.shader)
						];
					}
				});
			}
		});
	}