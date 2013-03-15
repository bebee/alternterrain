package examples
{
	import alternativa.engine3d.controllers.SimpleObjectController;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.Resource;
	import alternativa.engine3d.core.VertexAttributes;
	import alternativa.engine3d.core.View;
	import alternativa.engine3d.lights.AmbientLight;
	import alternativa.engine3d.lights.DirectionalLight;
	import alternativa.engine3d.loaders.ParserCollada;
	import alternativa.engine3d.materials.NormalMapSpace;
	import alternativa.engine3d.materials.StandardTerrainMaterial;
	import alternativa.engine3d.materials.TextureMaterial;
	import alternativa.engine3d.objects.Mesh;
	import alternativa.engine3d.objects.SkyBox;
	import alternativa.engine3d.primitives.Box;
	import alternativa.engine3d.primitives.Plane;
	import alternativa.engine3d.resources.BitmapTextureResource;
	import alternterrain.core.QuadTreePage;
	import alternterrain.objects.TerrainLOD;
	import alternterrain.resources.LoadAliases;
	import eu.nekobit.alternativa3d.materials.WaterMaterial;
	import flash.display.BitmapData;
	import flash.utils.ByteArray;
	
	import com.bit101.components.HSlider;
	import com.bit101.components.InputText;
	import com.bit101.components.Style;
	import com.bit101.components.Window;
	import com.bit101.utils.MinimalConfigurator;
	
	import flash.display.Sprite;
	import flash.display.Stage3D;
	import flash.display.StageAlign;
	import flash.display.StageDisplayState;
	import flash.display.StageScaleMode;
	import flash.display3D.Context3DRenderMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	[SWF(width="1100", height="600", frameRate="60")]
	public class ExampleTest extends Sprite
	{
		private var scene:Object3D = new Object3D();
		private var stage3D:Stage3D;
		private var camera:Camera3D;
		private var controller:SimpleObjectController;
		
		// Embeds
		
		[Embed(source="assets/water/sand.png")]
		static private const Ground:Class;
		
		[Embed(source="assets/water/plated-metal.png")]
		static private const PlatedMetal:Class;
		
		[Embed("assets/water/teapot.DAE", mimeType="application/octet-stream")]
		static private const Teapot:Class;		
		
		[Embed(source="assets/water/normal1.png")]
		static private const Normal1:Class;
		
		// Skybox
		
		private var sb:SkyBox;
		[Embed(source="assets/water/skybox/top.png")]
		static private const SBTop:Class;
		[Embed(source="assets/water/skybox/bottom.png")]
		static private const SBBottom:Class;
		[Embed(source="assets/water/skybox/front.png")]
		static private const SBFront:Class;
		[Embed(source="assets/water/skybox/back.png")]
		static private const SBBack:Class;
		[Embed(source="assets/water/skybox/left.png")]
		static private const SBLeft:Class;
		[Embed(source="assets/water/skybox/right.png")]
		static private const SBRight:Class;
		
		private var _normalMapData:BitmapData;
		private var settings:TemplateSettings = new TemplateSettings();
		
		
		[Embed(source="assets/myterrain.tre", mimeType="application/octet-stream")]
		private var TERRAIN_DATA:Class;
		
		[Embed(source="assets/myterrain_normal.jpg")]
		private var NORMAL_MAP:Class;
		
		[Embed(source="assets/edgeblend_mist.png")]
		private var EDGE:Class;
		
		public function ExampleTest()
		{
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			
			var loadAliases:LoadAliases = new LoadAliases();
			settings.cameraSpeed = 600;
			settings.cameraSpeedMultiplier = 16;
			settings.viewBackgroundColor = 0x3BB9FF;

			
			_normalMapData = new NORMAL_MAP().bitmapData;

			processDataAsLoadedPage( new TERRAIN_DATA() );
			
			stage3D = stage.stage3Ds[0];
			stage3D.addEventListener(Event.CONTEXT3D_CREATE, onContext3DCreated);
			stage3D.requestContext3D(Context3DRenderMode.AUTO);
			
			
		}
		
			private function processDataAsLoadedPage(data:ByteArray):void 
	{
		data.uncompress();
		
		_loadedPage = new QuadTreePage();
		_loadedPage.readExternal(data);
	
	}
		
		private var waterLevel:Number = -20000;
		private function onContext3DCreated(e:Event):void			
		{
			// Container
			
			// Camera
			camera = new Camera3D(1, 256*1024);
			camera.x = -315*256;
			camera.y = -315*256;
			camera.z = waterLevel + 66400;
			camera.rotationX = -1.595;
			camera.rotationZ = -0.6816;
			camera.view = new View(stage.stageWidth, stage.stageHeight);
			camera.view.antiAlias = 4;
			camera.diagramAlign = "left";
			camera.diagramHorizontalMargin = 5;
			camera.diagramVerticalMargin = 5;
			addChild(camera.view);
			addChild(camera.diagram);
			camera.view.hideLogo();			
			scene.addChild(camera);
			
			// Controller
			controller = new SimpleObjectController(camera.view, camera, 500, 4);
			
			  //Lightを追加
           var  ambientLight:AmbientLight = new AmbientLight(0xFFFFFF);
            ambientLight.intensity = 0.5;
            scene.addChild(ambientLight);
            
            //Lightを追加
           var  directionalLight:DirectionalLight = new DirectionalLight(0xFFFFFF);
            //手前右上から中央へ向けた指向性light
            directionalLight.x = 0;
            directionalLight.y = -100;
            directionalLight.z = 100;
            directionalLight.lookAt(0, 0, 0);
            scene.addChild(directionalLight);
			
			
			// TerrainLOD
			var terrainLOD:TerrainLOD = new TerrainLOD();
			var standardMaterial:StandardTerrainMaterial = new StandardTerrainMaterial( new BitmapTextureResource(_normalMapData), new BitmapTextureResource( _normalMapData), null, null  );
			
			//throw new Error([standardMaterial.opaquePass, standardMaterial.alphaThreshold, standardMaterial.transparentPass]);
			//standardMaterial.transparentPass = false;
			standardMaterial.normalMapSpace = NormalMapSpace.OBJECT;
			standardMaterial.specularPower = 0;
			standardMaterial.glossiness = 0;
			//standardMaterial.mistMap = new BitmapTextureResource(new EDGE().bitmapData);
			//StandardTerrainMaterial.fogMode = 1;
			StandardTerrainMaterial.fogFar = camera.farClipping = 256 * 800;
			StandardTerrainMaterial.fogNear = 256 * 32;
			StandardTerrainMaterial.fogColor = settings.viewBackgroundColor;
			standardMaterial.waterLevel = waterLevel;
			//standardMaterial.waterMode = 1;
			
			
		

			terrainLOD.loadSinglePage(stage3D.context3D, _loadedPage, standardMaterial, 256 * 1024 );  //new FillMaterial(0xFF0000, 1)
			terrainLOD.x -= terrainLOD.boundBox.maxX * .5;
			terrainLOD.y += terrainLOD.boundBox.maxX * .5;
		
		uploadResources(terrainLOD.getResources());
			scene.addChild(terrainLOD);
			hideFromReflection.push(terrainLOD);
			

			
			// Uncomment and see how this affects rendered reflection
			/*
			 var obstacle:Box = new Box(100,100,100,1,1,1,false,new FillMaterial(0x00FF0F));
			obstacle.y = 0;
			obstacle.z =waterLevel+400;
			obstacle.x = 0;
			uploadResources(obstacle.getResources());		
			scene.addChild(obstacle);
			*/
			
			// GUI

			//createGUI();			
			
			// Render loop
			stage.addEventListener(Event.ENTER_FRAME, think);
			stage.addEventListener(Event.RESIZE, onResize);
		//	stage.addEventListener(MouseEvent.RIGHT_CLICK, function(e:Event):void {});
		}
		
		private function onResize(e:Event):void
		{
			camera.view.width = stage.stageWidth;
			camera.view.height = stage.stageHeight;
			
			if(optionsWindow)
				optionsWindow.x = stage.stageWidth - optionsWindow.width - 5;
		}
		
		private var waterMaterial:WaterMaterial;
		private var plane:Plane;
		private var teapot:Mesh;
		private var box:Box;
		private var underwaterPlane:Plane;
		private var teapotContainer:Object3D = new Object3D();
		
		// todo: some custom culling method to make up for absence of clipping planes?
		private var hideFromReflection:Vector.<Object3D> = new Vector.<Object3D>();
		
		private function think(e:Event):void
		{
		//	camera.startTimer();		
			controller.update();
		//	waterMaterial.update(stage3D, camera, plane, hideFromReflection);
			//camera.stopTimer();
			
			// Update teapot rotation			
			teapotContainer.rotationZ += 0.012;
			teapot.rotationZ -= 0.02;
			
			camera.render(stage3D);
		}
		
		private function uploadResources(resources:Vector.<Resource>):void
		{
			for each(var res:Resource in resources)
			{
				if(!res.isUploaded)
				{
					res.upload(stage3D.context3D);
				}				
			}
		}
		
		/*---------------------
		GUI
		---------------------*/
		
		private var guiContainer:Sprite = new Sprite();
		private static const view:XML =
			<comps>			
				<!-- Console -->
				<Window id="options" title="Water options" x="695" y="5" width="400" height="240" draggable="true" hasMinimizeButton="true">
					<VBox left="15" right="15" top="50" bottom="15" spacing="15">
						<HBox bottom="5" left="5" right="5">
							<Label text="Water tint color RGB:" />
							<InputText id="waterColorR" />
							<InputText id="waterColorG" />
							<InputText id="waterColorB" />
						</HBox>
						<HBox bottom="5" left="5" right="5" alignment="middle">
							<Label text="Water tint amount:" />
							<HSlider id="tintSlider" minimum="0.0" maximum="1.0" event="change:onTintChange"/>
						</HBox>
						<HBox bottom="5" left="5" right="5" alignment="middle">
							<Label text="Fresnel multiplier:" />
							<HSlider id="fresnelSlider" minimum="0.0" maximum="1.0" event="change:onFresnelCoefChange"/>
						</HBox>
						<HBox bottom="5" left="5" right="5" alignment="middle">
							<Label text="Reflection (fresnel -1) multiplier:" />
							<HSlider id="reflectionMultiplierSlider" minimum="0.0" maximum="1.0" event="change:onFresnelCoefChange"/>
						</HBox>
						<HBox bottom="5" left="5" right="5" alignment="middle">
							<Label text="Perturb reflection by:" />
							<HSlider id="perturbReflectiveSlider" minimum="0.0" maximum="0.5" event="change:onPerturbChange"/>
						</HBox>
						<HBox bottom="5" left="5" right="5" alignment="middle">
							<Label text="Perturb refraction by:" />
							<HSlider id="perturbRefractiveSlider" minimum="0.0" maximum="0.5" event="change:onPerturbChange"/>
						</HBox>
						<PushButton label="Enter full screen" event="click:onFSButtonClicked"/>
					</VBox>
				</Window>
			</comps>;
		
		private var waterColorR:InputText;
		private var waterColorG:InputText;
		private var waterColorB:InputText;
		private var fresnelSlider:HSlider;
		private var reflectionMultiplierSlider:HSlider;
		private var perturbReflectiveBy:HSlider;
		private var perturbRefractiveBy:HSlider;
		private var tintAmount:HSlider;
		private var optionsWindow:Window;		
		private var _loadedPage:QuadTreePage;

		
		private function createGUI():void
		{		
			// Style
			Style.setStyle(Style.DARK);
			
			stage.addChild(guiContainer);
			var minco:MinimalConfigurator = new MinimalConfigurator(this);
			minco.parseXML(view);
			
			// Get refs
			waterColorR = (minco.getCompById("waterColorR") as InputText);
			waterColorG = (minco.getCompById("waterColorG") as InputText);
			waterColorB = (minco.getCompById("waterColorB") as InputText);
			fresnelSlider = (minco.getCompById("fresnelSlider") as HSlider);
			reflectionMultiplierSlider = (minco.getCompById("reflectionMultiplierSlider") as HSlider);			
			perturbReflectiveBy = (minco.getCompById("perturbReflectiveSlider") as HSlider);
			perturbRefractiveBy = (minco.getCompById("perturbRefractiveSlider") as HSlider);
			tintAmount = (minco.getCompById("tintSlider") as HSlider);
			optionsWindow = (minco.getCompById("options") as Window);
			
			// Set defaults
			waterColorR.text = String(waterMaterial.waterColorR);
			waterColorG.text = String(waterMaterial.waterColorG);
			waterColorB.text = String(waterMaterial.waterColorB);
			fresnelSlider.value = waterMaterial.fresnelMultiplier;
			reflectionMultiplierSlider.value = waterMaterial.reflectionMultiplier;
			perturbReflectiveBy.value = waterMaterial.perturbReflectiveBy;
			perturbRefractiveBy.value = waterMaterial.perturbRefractiveBy;
			tintAmount.value = waterMaterial.waterTintAmount;
			
			// Add change listeners for tfs
			waterColorR.addEventListener(Event.CHANGE, onWaterColorChange);
			waterColorG.addEventListener(Event.CHANGE, onWaterColorChange);
			waterColorB.addEventListener(Event.CHANGE, onWaterColorChange);
		}
		
		/*---------------------
		GUI event handlers
		---------------------*/
		
		public function onWaterColorChange(e:Event):void
		{
			waterMaterial.waterColorR = parseFloat(waterColorR.text);
			waterMaterial.waterColorG = parseFloat(waterColorG.text);
			waterMaterial.waterColorB = parseFloat(waterColorB.text);
		}
		
		public function onFresnelCoefChange(e:Event):void
		{
			waterMaterial.fresnelMultiplier = fresnelSlider.value;
			waterMaterial.reflectionMultiplier = reflectionMultiplierSlider.value;
		}	
		
		public function onPerturbChange(e:Event):void
		{
			waterMaterial.perturbReflectiveBy = perturbReflectiveBy.value;
			waterMaterial.perturbRefractiveBy = perturbRefractiveBy.value;
		}
		
		public function onTintChange(e:Event):void
		{
			waterMaterial.waterTintAmount = tintAmount.value;
		}
		
		public function onFSButtonClicked(e:Event):void
		{
			stage.displayState = StageDisplayState.FULL_SCREEN;			
		}
	}
}

class TemplateSettings {
	public var cameraSpeedMultiplier:Number = 3;
	public var cameraSpeed:Number = 100;
	public var cameraSensitivity:Number = 1;
	public var viewBackgroundColor:uint;
	
}