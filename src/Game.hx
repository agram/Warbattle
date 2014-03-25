import Common;
import hxd.Key in K;
import hxd.Math;

class Game extends hxd.App
{
	public static var cacheItem:Path.Item;
	public static var cachePoint:Tools.MyPoint;	

	public var keysActive : AllKeys;
	
	public var width:Float;
	public var height:Float;
	
	public static var inst : Game;	
	public var ents:Array<Ent>;
	
	public var boardBackground:h2d.Layers;
	public var board:h2d.Layers;
	public var boardUi:h2d.Layers;
	
	var pause:Bool;
	public var start:Bool;
	
	public var player: Joueur;
	public var opponent: Joueur;
	
	public var skillZones:Array<SkillZone>;
	
	public var message:Message;
	public var messageSkills:Message;
	
	public var zoneSelection: {
		begin: { x:Float, y:Float },
		end: { x:Float, y:Float },
		zone:Ent,
	};
	
	public var gameInteractive:h2d.Interactive;
	public var modeAttackMove:Bool;
	
	public var traps:Array<Piege>;
	
	var textureFogofwar: h3d.mat.Texture;
	var matricePixel: haxe.io.Bytes;
	var tileFogofwar: h2d.Tile;
	var bitmapFogofwar: h2d.Bitmap;
	
	var deployZone:h2d.Bitmap;
	var deployZone2:h2d.Bitmap;
	var boutonStart:Message;

	var cursorAttackMove:h2d.Anim;
	
	override function init() {
		
		s2d.setFixedSize(Const.BASE_WIDTH, Const.BASE_HEIGHT);
		engine.backgroundColor = 0x0000FF;
		ents = [];
		boardBackground = new h2d.Layers();
		boardUi = new h2d.Layers();
		board = new h2d.Layers();
		s2d.add(boardBackground, 1);
		s2d.add(board, 2);
		s2d.add(boardUi, 4);		
	
		player = new Joueur (true);
		opponent = new Joueur (false);

		new MapGame();
		
		initGfx();
		pause = false;
		
		cacheItem = null;
		cachePoint = null;
		
		matricePixel = haxe.io.Bytes.alloc(128*128*4);
		textureFogofwar = new h3d.mat.Texture(128, 128);
		tileFogofwar = h2d.Tile.fromTexture(textureFogofwar);
		bitmapFogofwar = new h2d.Bitmap( tileFogofwar );
		
		// --- 

		start = false;

		initZoneSelection();
		
		new Scroll();
		
		deployTroups();
		boutonStart = null;
		
		modeAttackMove = false;
		cursorAttackMove = null;
		
		traps = [];

		boutonStart = new Message();
		boardUi.addChild(boutonStart);
		boutonStart.texte.text = 'START';
		boutonStart.width = 75;
		boutonStart.height = 30;
		boutonStart.alpha = 0.5;
		boutonStart.x = Const.MAP_WIDTH - boutonStart.width;
		boutonStart.y = Const.MAP_HEIGHT - boutonStart.height;
		var i = new h2d.Interactive(boutonStart.width, boutonStart.height, boutonStart);
		i.onClick = function (_) { startGame(); }

	}
	
	public function startGame() {
		var nb = 0;
		for (t in player.troups) nb += (t.deployed)? 1 : 0 ;
		if (nb != 4) return ;
		
		var a = Std.random(500) + 50;
		for (i in 0...opponent.troups.length) {
			var t = opponent.troups[i];
			t.x = a + i * 50;
			t.icone.x = a + i * 50;
		}

		for (t in player.troups.copy()) {
			if (!t.deployed) t.destroy(false);
			else t.iDeploy.remove();
		}
		for(t in opponent.troups) t.iDeploy.remove();
		
		skillZones = [];
		skillZones.push(new SkillZone(1));
		skillZones.push(new SkillZone(2));
		skillZones.push(new SkillZone(0));
		
		deactivateAttackMove();
		
		for (t in player.troups) t.activate();
		//for (t in opponent.troups) t.activateOppositeTroup();
		for (t in opponent.troups) t.activate();
		
		initInteractiveOnGround();
		
		deployZone.remove();
		deployZone2.remove();
		
		message.visible = false;
		messageSkills.visible = false;
		
		start = true;
		
		boutonStart.remove();

		player.initLivingTroups ();
		opponent.initLivingTroups ();
	}
	
	override function update( dt : Float ) {
		
		if (!start) {
			
			var nb = 0;
			for (t in player.troups) nb += (t.deployed)? 1 : 0 ;
			switch (nb) {
			case 4 : boutonStart.alpha = 1;
			default: boutonStart.alpha = 0.5; return ;
			}
			
			for (e in ents.copy()) e.update(dt);
			return;
		}
		
		updateFogofwar();
		
		if (player.troups.length == 0) throw ('PERDU');
		if (opponent.troups.length == 0) throw ('GAGNE');
				
		traitementClavier();
	
		if ( hxd.Key.isPressed("P".code) ) pause = !pause;
		if (pause) return;

		if ( hxd.Key.isDown("S".code) ) dt *= 0.2;

		Scroll.updateScroll(keysActive);
		
		updateZoneSelection();
		
		traitementCommande();
		
		updateSkillzone();
		
		for (t in player.troups.copy()) t.update(dt);
		for (t in opponent.troups.copy()) t.update(dt);

		// Chacune des troupes collisionne les troupes de l'autre camps.
		for (t1 in player.troups) for (t2 in opponent.troups) t1.onCollide(t2);
		
		for (e in ents.copy()) e.update(dt);
		
		for (i in 0...ents.length - 1) {
			for (j in i + 1...ents.length) {
				var a = ents[i];
				var b = ents[j];
				a.onCollide(b);
				if(a != null && b != null)
					b.onCollide(a);
			}
		}

		player.update();
		opponent.update();
		
		updateVision();
		
		board.ysort(Const.L_UNIT); 
	}
	
	function updateVision() {
		for (t in player.troups) {
			t.vu = false;
			if (t.dead) t.destroy();
		}
		for (t in opponent.troups) {
			t.vu = false;
			if (t.dead) t.destroy();
		}
		
		var t1:Troup;
		var t2:Troup;
		for (t1 in player.troups) for (t2 in opponent.troups) {
			var vu = false;
			if (Tools.distanceSquare(t1.x, t2.x, t1.y, t2.y) < 16384) // (128 pixels de distance pour la vision) 
				vu = calcLine( t1.x, t2.x, t1.y, t2.y);
			
			t1.vu = t1.vu || vu;
			t2.vu = t2.vu || vu;
			t1.tabBrezenham[Std.int(t1.numero * opponent.troups.length + t2.numero)] = vu;
			if (t1.isCloack()) t1.vu = false;
			if (t2.isCloack()) t2.vu = false;
			if (player.scan()) t2.vu = true;
			if (opponent.scan()) t1.vu = true;
			
		}
			
		for (t in opponent.troups) t.icone.visible = t.vu; 		
	}
	
	function updateSkillzone () {
		for (sz in skillZones) {
			if (sz.skill != null && sz.skill.cooldown > 1) {
				sz.show(sz.skill, true);
			}
			else if (sz.skill != null && sz.skill.cooldown == 1) {
				sz.skill.cooldown = 0;
				sz.show(sz.skill);
			}
		}
	}
	
	function traitementClavier() {
		keysActive = {
			up : K.isDown(K.UP),
			down : K.isDown(K.DOWN),
			left : K.isDown(K.LEFT),
			right : K.isDown(K.RIGHT),
			a : K.isPressed("A".code) || K.isPressed("Q".code),
			z : K.isPressed("Z".code) || K.isPressed("W".code),
			e : K.isPressed("E".code),
			shift : K.isDown(K.SHIFT),
			cancel : K.isPressed(K.ESCAPE),
		}
				
	}
	
	function traitementCommande () {
		if (keysActive.cancel) {
			if (player.selectedSkill != null) player.selectedSkill.deactivate();
			else for (t in player.troups) t.unselect();
			deactivateAttackMove();
		}
		
		if (keysActive.a) {
			if (player.selectedSkill != null) player.selectedSkill.deactivate();
			if (player.selectedTroup != null) activateAttackMove();
			else {
				for (t in player.troups) 
					if (t.selected) { 
						activateAttackMove(); 
						break; 
						};
			}
		}
		
		if (keysActive.z) {
			if (player.selectedTroup != null) {
				var skill = player.selectedTroup.skills[0];
				if (skill != null && !skill.troup.dead && !skill.troup.isFourmi() && !skill.troup.isStun() && skill.isActif() ) {
					if (modeAttackMove) deactivateAttackMove();
					skill.activate();
					switch(skill.code) {
						case ATTAQUE_TOURNOYANTE, COUP_BOUCLIER, CHARGE_FRENETIC, SCAN:
						default : skillZones[0].activated();
					}
				}
			}
		}
		
		if (keysActive.e) {
			if (player.selectedTroup != null) {
				var skill = player.selectedTroup.skills[1];
				if (skill != null && !skill.troup.dead && !skill.troup.isFourmi() && !skill.troup.isStun() && skill.isActif() ) {
					if (modeAttackMove) deactivateAttackMove();
					skill.activate();
					switch(skill.code) {
						case ATTAQUE_TOURNOYANTE, COUP_BOUCLIER, CHARGE_FRENETIC, SCAN:
						default : skillZones[1].activated();
					}
				}
			}
		}		
	}
	
	function updateFogofwar() {
		// Traitement du fog of war
		for (i in 0...128 ) for (j in 0...128) {
			matricePixel.set((i * 128  + j) * 4, 0x80);
			matricePixel.set((i * 128  + j) * 4 + 1, 0x00);
			matricePixel.set((i * 128  + j) * 4 + 2 , 0x00);
			matricePixel.set((i * 128  + j) * 4 + 3, 0x00);
		}
		
		for (t in player.troups) {
			var beginX = Std.int(Math.max(0, t.x / 8 - 16));
			var endX = Std.int(Math.min(t.x / 8 + 16, 96));
			var beginY = Std.int(Math.max(0, t.y / 8 - 16));
			var endY = Std.int(Math.min(t.y / 8 + 16, 54));
			for (i in beginX...endX) for (j in beginY...endY) {
				var newX = Std.int(t.x / 8);
				var newY = Std.int(t.y / 8);
				if(
					Tools.distanceSquare(newX, i, newY, j) < 16 * 16 
					&& player.obstacle[i * 8 + Const.MAP_WIDTH * j * 8] != -1 
					&& calcLineFogofwar(newX , i, newY, j) 
				) {
					//throw(newX + ', ' +  i + ', ' + newY +', ' + j);
					matricePixel.set((i + j * 128 ) * 4, 0x00);
				}
			}
			
			//matricePixel.set( ((Std.int(t.x) >> 3) + ((Std.int(t.y) >> 3) << 7)) << 2, 0x00);
		}

		textureFogofwar.uploadPixels(new hxd.Pixels(128, 128, matricePixel, ARGB));
		tileFogofwar = h2d.Tile.fromTexture(textureFogofwar);
		bitmapFogofwar.remove();
		bitmapFogofwar = new h2d.Bitmap( tileFogofwar );
		bitmapFogofwar.scale(8);
		board.add(bitmapFogofwar, Const.L_FOGOFWAR);
		
	}
	
	function updateZoneSelection () {
		if (zoneSelection.begin != null && zoneSelection.end != null ) {
			var a:Float;
			var w:Float;
			var b:Float;
			var h:Float;
			if (zoneSelection.begin.x < zoneSelection.end.x) {
				a = zoneSelection.begin.x;
				w = zoneSelection.end.x - zoneSelection.begin.x;
			}
			else {
				a = zoneSelection.end.x;
				w = zoneSelection.begin.x - zoneSelection.end.x;
			}
			if (zoneSelection.begin.y < zoneSelection.end.y) {
				b = zoneSelection.begin.y;
				h = zoneSelection.end.y - zoneSelection.begin.y;
			}
			else {
				b = zoneSelection.end.y;
				h = zoneSelection.begin.y - zoneSelection.end.y;
			}
			zoneSelection.zone.mc.x = a;
			zoneSelection.zone.mc.y = b;
			zoneSelection.zone.mc.scaleX = w / Const.MAP_WIDTH;
			zoneSelection.zone.mc.scaleY = h / Const.MAP_HEIGHT;
			zoneSelection.zone.mc.visible = true;
		}
		else zoneSelection.zone.mc.visible = false;
	}
	
	function releaseSelection (x, y) {
		zoneSelection.end = { x: x, y:y }; 
		
		if (zoneSelection.begin == null) return;
		
		// Je dessine le carré de facon qu'il soit à l endroit, ca simplifie les calculs.
		if (zoneSelection.begin.x > zoneSelection.end.x) {
			var a = zoneSelection.begin.x;
			zoneSelection.begin.x = zoneSelection.end.x;
			zoneSelection.end.x = a;
		}
		if (zoneSelection.begin.y > zoneSelection.end.y) {
			var a = zoneSelection.begin.y;
			zoneSelection.begin.y = zoneSelection.end.y;
			zoneSelection.end.y = a;
		}
		
		// Si le carré est trop petit, je n'en tiens pas compte.
		if ( zoneSelection.end.x - zoneSelection.begin.x < 20 || zoneSelection.end.y < 20 - zoneSelection.begin.x ) {
			zoneSelection.begin = null;
			zoneSelection.end = null;
			return;
		}
				
		if(player.selectedSkill == null) {
			for (t in player.troups) t.unselect();
			for (t in player.troups) 
				if ( zoneSelection.begin.x < t.x 
				&& zoneSelection.end.x > t.x 
				&& zoneSelection.begin.y < t.y 
				&& zoneSelection.end.y > t.y 
				) t.select(true);
			zoneSelection.begin = null;
			zoneSelection.end = null;
		}
	}
	
	function initInteractiveOnGround() {

		gameInteractive.enableRightButton = true;
		gameInteractive.onClick = function (e) { 
			// si une unité est sélectionne et que l'on clique droit, on déplace l'unité
			if (e.button == 0) {
				if ( modeAttackMove ) {
					for (t in player.troups) if (t.selected) t.setGoal(e.relX, e.relY, true); 
					deactivateAttackMove();
				}
				else if (player.selectedSkill != null && !player.selectedTroup.isStun() && !player.selectedTroup.isFourmi()) {
					player.selectedSkill.actionOnGround(e);
				}
			}
			else { 
				if (player.selectedSkill != null) player.selectedSkill.deactivate();
				else if (modeAttackMove) deactivateAttackMove();
				else for (t in player.troups) if (t.selected) t.setGoal(e.relX, e.relY, false); 
			}
		}

		// Traitement de la zone de sélection
		gameInteractive.onPush = function (e) {
			if (player.selectedSkill == null && e.button == 0 && zoneSelection.begin == null) 
				zoneSelection.begin = { 
					x: e.relX * (1 + 0.1 * Scroll.ZOOM) + boardBackground.x, 
					y: e.relY * (1 + 0.1 * Scroll.ZOOM) + boardBackground.y
				};
		};
		gameInteractive.onMove = function (e) { 
			moveCursor(e, boardBackground.x, boardBackground.y); 
		};
		
		gameInteractive.onRelease = function (e) {
			if (e.button == 0) 
				releaseSelection(
					e.relX * (1 + 0.1 * Scroll.ZOOM) + boardBackground.x, 
					 e.relY * (1 + 0.1 * Scroll.ZOOM) + boardBackground.y
				);
		};
		
		// Zoom
		gameInteractive.onWheel = function (e) {
			Scroll.wheel(e);
		}
		
	}
	
	public function moveCursor(e:hxd.Event, xx, yy) {
		if (player.selectedSkill != null && player.selectedSkill.animCursor != null) {
			
			player.selectedSkill.animCursor.x = e.relX * (1 + 0.1 * Scroll.ZOOM) - 8 + xx;
			player.selectedSkill.animCursor.y = e.relY * (1 + 0.1 * Scroll.ZOOM) - 8 + yy;
		}
		if (modeAttackMove) {
			cursorAttackMove.x = e.relX * (1 + 0.1 * Scroll.ZOOM) - 8 + xx;
			cursorAttackMove.y = e.relY * (1 + 0.1 * Scroll.ZOOM) - 8 + yy;
		}


		if (zoneSelection.begin != null) 
			zoneSelection.end = { 
				x: e.relX * (1 + 0.1 * Scroll.ZOOM) + xx, 
				y: e.relY * (1 + 0.1 * Scroll.ZOOM) + yy
			}; 
	}
	
	function calcLineFogofwar( x1, x2, y1, y2) {
		var vu = true;				
		Tools.Bresenham.search(x1, y1, x2, y2, 
			function(ax, ay) { 
				switch (player.obstacle[Std.int(ax * 8 + Const.MAP_WIDTH * ay * 8)]) { 
				case -1:
					vu = false; 
					return true;
				default :
					return false;
				}
			}
		);
		return vu;
	}
	
	function calcLine( x1, x2, y1, y2) {
		var vu = true;				
		Tools.Bresenham.search(x1, y1, x2, y2, 
			function(ax, ay) { 
				switch (player.obstacle[Std.int(ax + Const.MAP_WIDTH * ay)] ) {
				case -1, -3 :  
					vu = false; 
					return true;
				default: 	
					return false;
				}
			}
		);
		return vu;
	}
	
	public function activateAttackMove() {
		if (modeAttackMove) return;
		
		gameInteractive.cursor = Hide;
		modeAttackMove = true;
		if (player.selectedTroup != null ) {
			cursorAttackMove = new h2d.Anim( 
			switch(player.selectedTroup.code) {
			case CHASSEUR, ARCHER, ASSASSIN : gfx.particule.amoveDistance;
			case TANK, SOLDAT, TROLL, HERO : gfx.particule.amoveMelee;
			case MAGICIEN, NECROMANCIEN, ORACLE : gfx.particule.amoveMagie;
				
			}, boardUi);
		}
		else cursorAttackMove = new h2d.Anim(gfx.particule.amoveMelee, boardUi);
		cursorAttackMove.colorKey = 0xFFFFFFFF;
		
		cursorAttackMove.x = s2d.mouseX * (1 + 0.1 * Scroll.ZOOM) - 8;
		cursorAttackMove.y = s2d.mouseX * (1 + 0.1 * Scroll.ZOOM) - 8;

		skillZones[2].bgSelected.visible = true;
	}
	
	public function deactivateAttackMove() {
		gameInteractive.cursor = Move;
		modeAttackMove = false;
		if (cursorAttackMove != null) {
			cursorAttackMove.remove();
			cursorAttackMove = null;
		}
		
		skillZones[2].bgSelected.visible = false;
	}
	
	function initZoneSelection () {
		zoneSelection = {
			begin: null,
			end: null,
			zone: new Ent (0,0, 20),
		}
		zoneSelection.zone.mc = new h2d.Graphics(boardUi);
		zoneSelection.zone.mc.visible = false;
		zoneSelection.zone.mc.beginFill(0x80808080);
		zoneSelection.zone.mc.drawRect(0, 0, Const.MAP_WIDTH, Const.MAP_HEIGHT);
		zoneSelection.zone.mc.alpha = 0.5;
		zoneSelection.zone.mc.endFill();
	}
	
	function deployTroups () { 
	
		var fg = h2d.Tile.fromColor(0x80808080, 60, 339);
		deployZone = new h2d.Bitmap(fg, board);
		deployZone.x = Const.MAP_WIDTH - 60;
		deployZone.y = 0;
		
		var fg = h2d.Tile.fromColor(0x80808080, Const.MAP_WIDTH, Const.MAP_HEIGHT - Const.Y_DEPLOY);
		deployZone2 = new h2d.Bitmap(fg, board);
		deployZone2.x = 0;
		deployZone2.y = Const.Y_DEPLOY ;
		
		var tab = [HERO, CHASSEUR, ARCHER, ASSASSIN, TANK, SOLDAT, TROLL, MAGICIEN, NECROMANCIEN, ORACLE];
		for (i in 0...tab.length) player.troups.push(new Troup(740, i * 33 + 20, tab[i], 1));
		for (i in 0...player.troups.length) player.troups[i].deployed = false;
		
		var tab = [CHASSEUR, ARCHER, TANK, SOLDAT, TROLL, MAGICIEN, NECROMANCIEN, ASSASSIN, ORACLE, HERO];
		for (i in 0...4) {
			var a = Std.random(tab.length);
			opponent.troups.push(new Troup(75 * i + 50, 50, tab[a], 2));
			tab.remove(tab[a]);
		}
		
		for (t in player.troups) t.initSkills();
		for (t in opponent.troups) t.initSkills();
		
		message = new Message();
		boardUi.addChild(message);
		message.texte.text = 'Choisissez 4 unités pour contrer l\'armée ennemi\nDéployez-lez dans la zone de combat\nPuis cliquez sur Start';
		message.y -= 110;
		message.height = 60 ;

		messageSkills = new Message();
		boardUi.addChild(messageSkills);
		messageSkills.texte.text = 'Description : \n\n\n\n\nCaractéristiques : ';
		messageSkills.y -= 50;
		messageSkills.height = 150;

		for (t in player.troups) t.activateForDeploy();
		for (t in opponent.troups) t.activateForDeploy();
		
		gameInteractive = new h2d.Interactive(Const.MAP_WIDTH, Const.MAP_HEIGHT, boardBackground);
		gameInteractive.onClick = function (e) { 			
				if (player.selectedTroup == null || e.relY < Const.Y_DEPLOY || player.obstacle[Std.int(e.relX + Const.MAP_WIDTH * e.relY)] != 0) {
					return;
				}
				player.selectedTroup.x = e.relX;
				player.selectedTroup.y = e.relY;
				player.selectedTroup.icone.x = e.relX;
				player.selectedTroup.icone.y = e.relY;
				player.selectedTroup.deployed = true;
		}
	}
	
	public var gfx: {
		troups: {
			hero:Array<h2d.Tile>,
			soldat:Array<h2d.Tile>,
			archer:Array<h2d.Tile>,
			cavalerie:Array<h2d.Tile>,
			catapulte:Array<h2d.Tile>,
			walker:Array<h2d.Tile>,
		},
		states: {
			stun: Array<h2d.Tile>,
			poison: Array<h2d.Tile>,
			sprint: Array<h2d.Tile>,
			bouclier: Array<h2d.Tile>,
			charge: Array<h2d.Tile>,
			berserk: Array<h2d.Tile>,
			dodo: Array<h2d.Tile>,
			scan: Array<h2d.Tile>,
			powerAura: Array<h2d.Tile>,
		},		
		personnages: {
			gentilNormal:	{
				chasseur:Array<h2d.Tile>,
				archer:Array<h2d.Tile>,
				tank:Array<h2d.Tile>,
				soldat:Array<h2d.Tile>,
				troll:Array<h2d.Tile>,
				magicien:Array<h2d.Tile>,
				necromancien:Array<h2d.Tile>,
				assassin:Array<h2d.Tile>,
				oracle:Array<h2d.Tile>,
				hero:Array<h2d.Tile>,
			},
			gentilSelected:	{
				chasseur:Array<h2d.Tile>,
				archer:Array<h2d.Tile>,
				tank:Array<h2d.Tile>,
				soldat:Array<h2d.Tile>,
				troll:Array<h2d.Tile>,
				magicien:Array<h2d.Tile>,
				necromancien:Array<h2d.Tile>,
				assassin:Array<h2d.Tile>,
				oracle:Array<h2d.Tile>,
				hero:Array<h2d.Tile>,
			},
			mechant: {
				chasseur:Array<h2d.Tile>,
				archer:Array<h2d.Tile>,
				tank:Array<h2d.Tile>,
				soldat:Array<h2d.Tile>,
				troll:Array<h2d.Tile>,
				magicien:Array<h2d.Tile>,
				necromancien:Array<h2d.Tile>,
				assassin:Array<h2d.Tile>,
				oracle:Array<h2d.Tile>,
				hero:Array<h2d.Tile>,
			},
		},
		message: {
			main: Array<h2d.Tile>,
			statsTroup: Array<h2d.Tile>,
			a: Array<h2d.Tile>,
			z: Array<h2d.Tile>,
			e: Array<h2d.Tile>,
		},
		particule: {
			arrow: Array<h2d.Tile>,
			arrowPoison: Array<h2d.Tile>,
			arrowMagic: Array<h2d.Tile>,
			death: Array<h2d.Tile>,
			fight: Array<h2d.Tile>,
			goal: Array<h2d.Tile>,
			trap: Array<h2d.Tile>,
			fireball: Array<h2d.Tile>,
			curse: Array<h2d.Tile>,
			fourmi: Array<h2d.Tile>,
			amoveMelee: Array<h2d.Tile>,
			amoveDistance: Array<h2d.Tile>,
			amoveMagie: Array<h2d.Tile>,
		},
		skills: {
			poison: Array<h2d.Tile>,
			piege: Array<h2d.Tile>,
			teleportation: Array<h2d.Tile>,
			fireball: Array<h2d.Tile>,
			curse: Array<h2d.Tile>,
			metamorphose: Array<h2d.Tile>,
			assassinat: Array<h2d.Tile>,
			dodo: Array<h2d.Tile>,
		},
		map: {
			water: {
				all:Array<h2d.Tile>,
				grass: {
					bottomright:Array<h2d.Tile>,
					bottom:Array<h2d.Tile>,
					bottomleft:Array<h2d.Tile>,
					right:Array<h2d.Tile>,
					left:Array<h2d.Tile>,
					upright:Array<h2d.Tile>,
					up:Array<h2d.Tile>,
					upleft:Array<h2d.Tile>,
				},
				earth: {
					bottomright:Array<h2d.Tile>,
					bottom:Array<h2d.Tile>,
					bottomleft:Array<h2d.Tile>,
					right:Array<h2d.Tile>,
					left:Array<h2d.Tile>,
					upright:Array<h2d.Tile>,
					up:Array<h2d.Tile>,
					upleft:Array<h2d.Tile>,
				},
				stone: {
					bottomright:Array<h2d.Tile>,
					bottom:Array<h2d.Tile>,
					bottomleft:Array<h2d.Tile>,
					right:Array<h2d.Tile>,
					left:Array<h2d.Tile>,
					upright:Array<h2d.Tile>,
					up:Array<h2d.Tile>,
					upleft:Array<h2d.Tile>,
				},
			},
			grass: {
				all: {
					one:Array<h2d.Tile>,
					two:Array<h2d.Tile>,
					free:Array<h2d.Tile>,
					four:Array<h2d.Tile>,
				},
				water: {
					bottomright:Array<h2d.Tile>,
					bottomleft:Array<h2d.Tile>,
					upright:Array<h2d.Tile>,
					upleft:Array<h2d.Tile>,
				},
				earth: {
					bottomright:Array<h2d.Tile>,
					bottomleft:Array<h2d.Tile>,
					upright:Array<h2d.Tile>,
					upleft:Array<h2d.Tile>,
				},
				stone: {
					bottomright:Array<h2d.Tile>,
					bottomleft:Array<h2d.Tile>,
					upright:Array<h2d.Tile>,
					upleft:Array<h2d.Tile>,
				},
			},
			void: {
				all:Array<h2d.Tile>,
				grass: {
					bottomright:Array<h2d.Tile>,
					bottom:Array<h2d.Tile>,
					bottomleft:Array<h2d.Tile>,
					right:Array<h2d.Tile>,
					left:Array<h2d.Tile>,
					upright:Array<h2d.Tile>,
					up:Array<h2d.Tile>,
					upleft:Array<h2d.Tile>,
				},
			},
			earth: {
				all:Array<h2d.Tile>,
				grass: {
					bottomright:Array<h2d.Tile>,
					bottom:Array<h2d.Tile>,
					bottomleft:Array<h2d.Tile>,
					right:Array<h2d.Tile>,
					left:Array<h2d.Tile>,
					upright:Array<h2d.Tile>,
					up:Array<h2d.Tile>,
					upleft:Array<h2d.Tile>,
				},
				water: {
					bottomright:Array<h2d.Tile>,
					bottomleft:Array<h2d.Tile>,
					upright:Array<h2d.Tile>,
					upleft:Array<h2d.Tile>,
				},
			},
			stone: {
				all:Array<h2d.Tile>,
				grass: {
					bottomright:Array<h2d.Tile>,
					bottom:Array<h2d.Tile>,
					bottomleft:Array<h2d.Tile>,
					right:Array<h2d.Tile>,
					left:Array<h2d.Tile>,
					upright:Array<h2d.Tile>,
					up:Array<h2d.Tile>,
					upleft:Array<h2d.Tile>,
				},
				water: {
					bottomright:Array<h2d.Tile>,
					bottomleft:Array<h2d.Tile>,
					upright:Array<h2d.Tile>,
					upleft:Array<h2d.Tile>,
				},
			},
		}
	};
	
	function initGfx() {	
		var tileGfx = Res.gfx.toTile();
		var tileGfx2 = Res.gfx2.toTile();
		var tileMap = Res.tileset_7.toTile();
		var w = 16;
		var h = 16;
		gfx =  {
			troups: {
				hero: Tools.split(tileGfx, 0, 0, 1, w, h),
				soldat: Tools.split(tileGfx, 1, 0, 1, w, h),
				archer: Tools.split(tileGfx, 2, 0, 1, w, h),
				cavalerie: Tools.split(tileGfx, 3, 0, 1, w, h),
				catapulte: Tools.split(tileGfx, 4, 0, 1, w, h),
				walker: Tools.split(tileGfx, 5, 0, 4, w, h),
			},
			states: {
				stun: Tools.split(tileGfx, 12, 0, 3, w, h),
				poison: Tools.split(tileGfx, 15, 0, 2, w, h),
				sprint: Tools.split(tileGfx, 17, 0, 2, w, h),
				bouclier: Tools.split(tileGfx, 19, 0, 1, w, h),
				charge: Tools.split(tileGfx, 20, 0, 2, w, h),
				berserk: Tools.split(tileGfx, 22, 0, 2, w, h),
				dodo: Tools.split(tileGfx, 8, 2, 3, 16, 16),
				scan: Tools.split(tileGfx, 13, 1, 1, 16, 16),
				powerAura: Tools.split(tileGfx, 14, 1, 1, 16, 16),
			},		
			personnages: {
				gentilNormal: {
					chasseur: Tools.split(tileGfx2, 0, 0, 1, 32, 32),
					archer: Tools.split(tileGfx2, 0, 1, 1, 32, 32),
					tank: Tools.split(tileGfx2, 0, 2, 1, 32, 32),
					soldat: Tools.split(tileGfx2, 0, 3, 1, 32, 32),
					troll: Tools.split(tileGfx2, 0, 4, 1, 32, 32),
					magicien: Tools.split(tileGfx2, 0, 5, 1, 32, 32),
					necromancien: Tools.split(tileGfx2, 0, 6, 1, 32, 32),
					assassin: Tools.split(tileGfx2, 0, 7, 1, 32, 32),
					oracle: Tools.split(tileGfx2, 0, 9, 1, 32, 32),
					hero: Tools.split(tileGfx2, 0, 10, 1, 32, 32),
				},
				gentilSelected: {
					chasseur: Tools.split(tileGfx2, 2, 0, 1, 32, 32),
					archer: Tools.split(tileGfx2, 2, 1, 1, 32, 32),
					tank: Tools.split(tileGfx2, 2, 2, 1, 32, 32),
					soldat: Tools.split(tileGfx2, 2, 3, 1, 32, 32),
					troll: Tools.split(tileGfx2, 2, 4, 1, 32, 32),
					magicien: Tools.split(tileGfx2, 2, 5, 1, 32, 32),
					necromancien: Tools.split(tileGfx2, 2, 6, 1, 32, 32),
					assassin: Tools.split(tileGfx2, 2, 7, 1, 32, 32),
					oracle: Tools.split(tileGfx2, 2, 9, 1, 32, 32),
					hero: Tools.split(tileGfx2, 2, 10, 1, 32, 32),
				},
				mechant: {
					chasseur: Tools.split(tileGfx2, 3, 0, 1, 32, 32),
					archer: Tools.split(tileGfx2, 3, 1, 1, 32, 32),
					tank: Tools.split(tileGfx2, 3, 2, 1, 32, 32),
					soldat: Tools.split(tileGfx2, 3, 3, 1, 32, 32),
					troll: Tools.split(tileGfx2, 3, 4, 1, 32, 32),
					magicien: Tools.split(tileGfx2, 3, 5, 1, 32, 32),
					necromancien: Tools.split(tileGfx2, 3, 6, 1, 32, 32),
					assassin: Tools.split(tileGfx2, 3, 7, 1, 32, 32),
					oracle: Tools.split(tileGfx2, 3, 9, 1, 32, 32),
					hero: Tools.split(tileGfx2, 3, 10, 1, 32, 32),
				},
			},
			message: {
				main: Tools.split(tileGfx, 0, 1, 1, 24, 24),
				statsTroup: Tools.split(tileGfx, 1, 1, 1, 24, 24),
				a: Tools.split(tileGfx, 9, 0, 1, 16, 16),
				z: Tools.split(tileGfx, 10, 0, 1, 16, 16),
				e: Tools.split(tileGfx, 11, 0, 1, 16, 16),
			},
			particule: {
				arrow: Tools.split(tileGfx, 0, 2, 1, 8, 8),
				arrowPoison: Tools.split(tileGfx, 5, 2, 1, 8, 8),
				arrowMagic: Tools.split(tileGfx, 0, 6, 2, 8, 8),
				death: Tools.split(tileGfx, 3, 1, 1, 16, 16),
				fight: Tools.split(tileGfx, 1, 2, 4, 8, 8),
				goal: Tools.split(tileGfx, 4, 1, 5, 16, 16),
				trap: Tools.split(tileGfx, 3, 2, 1, 16, 16),
				fireball: Tools.split(tileGfx, 1, 2, 8, 32, 32),
				curse: Tools.split(tileGfx, 0, 1, 3, 96, 96),
				fourmi: Tools.split(tileGfx2, 0, 8, 1, 32, 32),
				amoveMelee: Tools.split(tileGfx, 12, 3, 4, w, h),
				amoveDistance: Tools.split(tileGfx, 16, 3, 4, w, h),
				amoveMagie: Tools.split(tileGfx, 14, 2, 4, w, h),
			},
			skills: {
				poison: Tools.split(tileGfx, 6, 3, 3, 16, 16),
				piege: Tools.split(tileGfx, 9, 3, 3, 16, 16),
				teleportation: Tools.split(tileGfx, 5, 0, 4, 16, 16),
				fireball: Tools.split(tileGfx, 1, 3, 5, 16, 16),
				curse: Tools.split(tileGfx, 3, 2, 2, 16, 16),
				metamorphose: Tools.split(tileGfx, 2, 2, 2, 16, 16),
				assassinat:Tools.split(tileGfx, 11, 2, 3, 16, 16),
				dodo: Tools.split(tileGfx, 8, 2, 3, 16, 16),
			},
			map: {
				water: {
					all: Tools.split(tileMap, 3, 2, 1, w, h),
					grass: {
						bottomright: Tools.split(tileMap, 0, 0, 1, w, h),
						bottom: Tools.split(tileMap, 1, 0, 1, w, h),
						bottomleft: Tools.split(tileMap, 2, 0, 1, w, h),
						right: Tools.split(tileMap, 0, 1, 1, w, h),
						left: Tools.split(tileMap, 2, 1, 1, w, h),
						upright: Tools.split(tileMap, 0, 2, 1, w, h),
						up: Tools.split(tileMap, 1, 2, 1, w, h),
						upleft: Tools.split(tileMap, 2, 2, 1, w, h),
					},
					earth: {
						bottomright: Tools.split(tileMap, 10, 2, 1, w, h),
						bottom: Tools.split(tileMap, 11, 2, 1, w, h),
						bottomleft: Tools.split(tileMap, 12, 2, 1, w, h),
						right: Tools.split(tileMap, 10, 3, 1, w, h),
						left: Tools.split(tileMap, 12, 3, 1, w, h),
						upright: Tools.split(tileMap, 10, 4, 1, w, h),
						up: Tools.split(tileMap, 11, 4, 1, w, h),
						upleft: Tools.split(tileMap, 12, 4, 1, w, h),
					},
					stone: {
						bottomright: Tools.split(tileMap, 13, 2, 1, w, h),
						bottom: Tools.split(tileMap, 13, 2, 1, w, h),
						bottomleft: Tools.split(tileMap, 15, 2, 1, w, h),
						right: Tools.split(tileMap, 13, 3, 1, w, h),
						left: Tools.split(tileMap, 15, 3, 1, w, h),
						upright: Tools.split(tileMap, 13, 4, 1, w, h),
						up: Tools.split(tileMap, 14, 4, 1, w, h),
						upleft: Tools.split(tileMap, 15, 4, 1, w, h),
					},
				},
				grass: {
					all: {
						one: Tools.split(tileMap, 10, 0, 1, w, h),
						two: Tools.split(tileMap, 11, 0, 1, w, h),
						free: Tools.split(tileMap, 10, 1, 1, w, h),
						four: Tools.split(tileMap, 11, 1, 1, w, h),
					},
					water: {
						bottomright: Tools.split(tileMap, 3, 1, 1, w, h),
						bottomleft: Tools.split(tileMap, 4, 1, 1, w, h),
						upright: Tools.split(tileMap, 3, 2, 1, w, h),
						upleft: Tools.split(tileMap, 4, 2, 1, w, h),
					},
					earth: {
						bottomright: Tools.split(tileMap, 8, 4, 1, w, h),
						bottomleft: Tools.split(tileMap, 9, 4, 1, w, h),
						upright: Tools.split(tileMap, 8, 5, 1, w, h),
						upleft: Tools.split(tileMap, 9, 5, 1, w, h),
					},
					stone: {
						bottomright: Tools.split(tileMap, 12, 0, 1, w, h),
						bottomleft: Tools.split(tileMap, 13, 0, 1, w, h),
						upright: Tools.split(tileMap, 12, 1, 1, w, h),
						upleft: Tools.split(tileMap, 13, 1, 1, w, h),
					},
				},
				void: {
					all: Tools.split(tileMap, 3, 3, 1, w, h),
					grass: {
						bottomright: Tools.split(tileMap, 0, 3, 1, w, h),
						bottom: Tools.split(tileMap, 1, 3, 1, w, h),
						bottomleft: Tools.split(tileMap, 2, 3, 1, w, h),
						right: Tools.split(tileMap, 0, 4, 1, w, h),
						left: Tools.split(tileMap, 2, 4, 1, w, h),
						upright: Tools.split(tileMap, 0, 5, 1, w, h),
						up: Tools.split(tileMap, 1, 5, 1, w, h),
						upleft: Tools.split(tileMap, 2, 5, 1, w, h),
					},
				},
				earth: {
					all: Tools.split(tileMap, 4, 2, 1, w, h),
					grass: {
						bottomright: Tools.split(tileMap, 5, 0, 1, w, h),
						bottom: Tools.split(tileMap, 6, 0, 1, w, h),
						bottomleft: Tools.split(tileMap, 7, 0, 1, w, h),
						right: Tools.split(tileMap, 5, 1, 1, w, h),
						left: Tools.split(tileMap, 7, 1, 1, w, h),
						upright: Tools.split(tileMap, 5, 2, 1, w, h),
						up: Tools.split(tileMap, 6, 2, 1, w, h),
						upleft: Tools.split(tileMap, 7, 2, 1, w, h),
					},
					water: {
						bottomright: Tools.split(tileMap, 8, 4, 1, w, h),
						bottomleft: Tools.split(tileMap, 9, 4, 1, w, h),
						upright: Tools.split(tileMap, 8, 5, 1, w, h),
						upleft: Tools.split(tileMap, 9, 5, 1, w, h),
					},
				},
				stone: {
					all: Tools.split(tileMap, 4, 3, 1, w, h),
					grass: {
						bottomright: Tools.split(tileMap, 5, 3, 1, w, h),
						bottom: Tools.split(tileMap, 6, 3, 1, w, h),
						bottomleft: Tools.split(tileMap, 7, 3, 1, w, h),
						right: Tools.split(tileMap, 5, 4, 1, w, h),
						left: Tools.split(tileMap, 7, 4, 1, w, h),
						upright: Tools.split(tileMap, 5, 5, 1, w, h),
						up: Tools.split(tileMap, 6, 5, 1, w, h),
						upleft: Tools.split(tileMap, 7, 5, 1, w, h),
					},
					water: {
						bottomright: Tools.split(tileMap, 12, 0, 1, w, h),
						bottomleft: Tools.split(tileMap, 13, 0, 1, w, h),
						upright: Tools.split(tileMap, 12, 1, 1, w, h),
						upleft: Tools.split(tileMap, 13, 1, 1, w, h),
					},
				},
			},
		};
		
		//gfx.particule.goal.push(gfx.particule.goal[3]);
		gfx.particule.goal.push(gfx.particule.goal[2]);
		gfx.particule.goal.push(gfx.particule.goal[1]);
	}
	
	// --- 
	public static function main() {	
		hxd.Res.loader = new hxd.res.Loader(hxd.res.EmbedFileSystem.create(null,{compressSounds:true}));
		inst = new Game();
	}
}