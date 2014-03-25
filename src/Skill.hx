import Common;

class Skill
{
	var game:Game;
	
	public var code:SkillCode;
	public var troup:Troup;
	var aoe:h2d.Graphics;	
	
	public var range:Float;
	var color:Int;
	
	public var cooldown:Int;
	public var cooldownMax:Int;
	
	public var animCursor:h2d.Anim;
	
	public var executingTime:Int;
	
	public function new(troup:Troup, code:SkillCode) 
	{
		game = Game.inst;
		
		this.code = code;
		
		var fg:h2d.Tile;
		
		this.troup = troup;
		
		range = 100.;
		color = 0x80808080;
		
		range = switch(code) {
			case POISON: 		250;
			case PIEGE: 		150;
			case TELEPORTATION: 200;
			case FIREBALL: 		75;
			case CURSE: 		100;
			case METAMORPHOSE: 	75;
			case ASSASSINAT: 	50;
			case MINDCONTROL: 	0;
			case DODO: 			75;
			case POWER_AURA: 	300;
			default:
		}
		
		cooldownMax = switch(code) {
			case POISON: 		400;
			case PIEGE: 		500;
			case SPRINT: 		200;
			case COUP_BOUCLIER: 200;
			case ATTAQUE_TOURNOYANTE: 200;
			case CHARGE_FRENETIC: 1000;
			case BERSERK: 		1000;
			case TELEPORTATION: 800;
			case FIREBALL: 		900;
			case CURSE: 		300;
			case METAMORPHOSE: 	500;
			case CLOACK: 		250;
			case ASSASSINAT: 	250;
			case MINDCONTROL: 	50;
			case DODO: 			300;
			case SCAN: 			600;
			case RESURECT: 		1000;	
			default:
		}
		
		//cooldown = cooldownMax;
cooldown = 0;	
		
		animCursor = switch(code) {
			case POISON : new h2d.Anim(game.gfx.skills.poison, game.boardUi);
			case PIEGE : new h2d.Anim(game.gfx.skills.piege, game.boardUi);
			case TELEPORTATION : new h2d.Anim(game.gfx.skills.teleportation, game.boardUi);
			case FIREBALL : new h2d.Anim(game.gfx.skills.fireball, game.boardUi);
			case CURSE : new h2d.Anim(game.gfx.skills.curse, game.boardUi);
			case METAMORPHOSE : new h2d.Anim(game.gfx.skills.metamorphose, game.boardUi);
			case ASSASSINAT : new h2d.Anim(game.gfx.skills.assassinat, game.boardUi);
			case DODO : new h2d.Anim(game.gfx.skills.dodo, game.boardUi);
			default : null;
		}
		
		if (animCursor != null) {
			animCursor.visible = false;
			animCursor.colorKey = 0xFFFFFFFF;
		}
	}
	
	public static function getExecutingTime(code) {
		return switch(code) {
			case POISON: 		300; // temps d'empoisonnement *
			case PIEGE: 		300; // temps de stun *
			case SPRINT: 		300; // temps de sprint *
			case TIR_BARRAGE: 	50; // temps de sprint *
			case COUP_BOUCLIER: 300; // temps de stun *
			case LEVER_BOUCLIER: 120; // temps de ralentissement *
			case CHARGE_FRENETIC: 500; // temps de charge *
			case BERSERK: 		300; // temps d'invincibilité *
			case FIREBALL: 		150; // temps d'AOE *
			case CURSE: 		600; // temps d'AOE *
			case METAMORPHOSE: 	300; // temps de fourmi *
			case CLOACK: 		400; // temps de camouflage *
			case MINDCONTROL: 	300;  // temps de prise de controle *
			case DODO: 			300; // temps de sommeil *
			case SCAN: 			100; // temps de révélation
			case POWER_AURA:	 60; // temps de coupure de l'aura *
			default: 0;
		}
	}
		
	public function update() {
		if (cooldown > 0) cooldown--;
		if(aoe != null) {
			aoe.x = troup.icone.x;
			aoe.y = troup.icone.y;
		}
		
	}
	
	public function activate() {
		var g = troup.ally();
		if (g.selectedSkill != null) g.selectedSkill.deactivate();

		switch(code) {
			case SPRINT : 
				troup.sprint();
			case COUP_BOUCLIER : 
				if (troup.isFighting()) {
					troup.fights[0].coupBouclier();
					troup.use(COUP_BOUCLIER);
				}
			case ATTAQUE_TOURNOYANTE :
				troup.attaqueTournoyante();
			case CHARGE_FRENETIC :
				troup.chargeFrenetic();
			case CLOACK:
				troup.cloack();
			case ASSASSINAT :
				g.selectedSkill = this;
				if (troup.isCloack()) showAOE();
				else deactivate();
			case SCAN:
				use();
				Joueur.startScan(troup);
			case POISON, PIEGE, TELEPORTATION, FIREBALL, CURSE, METAMORPHOSE, MINDCONTROL, DODO:  
				g.selectedSkill = this;
				showAOE();
			default : 
		}
		
		if (animCursor != null) {
			animCursor.visible = true;
			game.gameInteractive.cursor = Hide;
		}
	}
	
	public function deactivate() {
		for (sz in game.skillZones) sz.deactivated();
		
		if (troup.isPlayer()) game.player.selectedSkill = null;
		else game.opponent.selectedSkill = null;
		
		closeAOE();
		
		game.gameInteractive.cursor = Move;
		animCursor.visible = false;
	}
	
	function testFriend (target:Troup, ennemy:Bool = true) {
		if (ennemy && target.isPlayer()) return false;
		else if (!ennemy && !target.isPlayer()) return false;
		
		return true;
	}
	
	function testRange(target:Troup, ennemy:Bool = true) { // si ennemy est à false, cela signifie ally
		if (!testFriend(target, ennemy)) return false;
		if (Tools.distanceSquare(troup.x, target.x, troup.y, target.y) <= range * range) return true;
		return false;
	}
	
	// Cette function renvoie true si l'action c'est bien passée, sinon, elle renvoie false.
	public function actionOnGround(e:hxd.Event) {
		
		switch(code) {
			case PIEGE : 
				if (Tools.distanceSquare(troup.x, e.relX, troup.y, e.relY) <= range * range 
				&& game.player.obstacle[Std.int(e.relX + Const.MAP_WIDTH * e.relY)] == 0 
				&& game.opponent.obstacle[Std.int(e.relX + Const.MAP_WIDTH * e.relY)] == 0 
				) {
					piege(e);
					deactivate();
				}
			case TELEPORTATION : 
				if (Tools.distanceSquare(troup.x, e.relX, troup.y, e.relY) <= range * range) {
					if (troup.teleport(e.relX, e.relY ))
						deactivate();
				}
			case FIREBALL :
				if (Tools.distanceSquare(troup.x, e.relX, troup.y, e.relY) <= range * range) {
					fireball(e);
					deactivate();
				}
			case CURSE :
				if (Tools.distanceSquare(troup.x, e.relX, troup.y, e.relY) <= range * range) {
					curse(e);
					deactivate();
				}
			default:
		}
		
	}
	
	public function actionOnAlly(target:Troup = null) {
		switch(code) {
			default: 
		}
	}
	
	public function actionOnEnnemy(target:Troup = null) {
		switch(code) {
			case POISON : 
				if (testRange(target, true)) {
					poison(target);
					deactivate();
				}
			case METAMORPHOSE : 
				if (testRange(target, true)) {
					metamorphose(target);
					deactivate();
				}
			case ASSASSINAT : 
				if (testRange(target, true) && troup.isCloack() ) {
					assassinate(target);
					deactivate();
				}
			case MINDCONTROL : 
				if (testRange(target, true) && !target.isControl() ) {
					mindControl(target);
					deactivate();
				}
			case DODO : 
				if (testRange(target, true)) {
					dodo(target);
					deactivate();
				}
			default: 
		}
	}
	
	function poison(target:Troup) {
		troup.poison = true;
		use();
		new Arrow(troup.x, troup.y, troup, target, POISON);
	}
	
	function piege (e) {
		game.traps.push(new Piege (e.relX, e.relY, troup.isPlayer()));
		use();
	}
	
	function fireball(e) {
		new Fireball(e.relX, e.relY);
		use();
	}
	
	function curse(e) {
		new Curse(e.relX, e.relY);
		use();
	}
	
	function metamorphose(target:Troup) {
		new TimerEffect( METAMORPHOSE, target);
		target.icone.anim.play(game.gfx.particule.fourmi);
		use();
	}
	
	public function assassinate(target:Troup) {
		target.looseLife(100, MAGIC);
		use();
	}
	
	public function dodo(target:Troup) {
		use();
		new TimerEffect(DODO, target);
	}
	
	public function mindControl(target:Troup) {
		target.goal = null;
		target.player = (target.player == 2)?1:2;
		new TimerEffect(MINDCONTROL, target);
		var g = target.allyTroups();
		var h = target.ennemyTroups();
		g.remove(target);
		h.push(target);
		use();		
		troup.icone.setAnim();
	}
	
	function use() {
		cooldown = cooldownMax;
	}
	
	public function closeAOE() {
		if (aoe != null) aoe.remove();
	}
	
	public function showAOE() {
		aoe = new h2d.Graphics(game.board);
		aoe.beginFill(color);
		aoe.drawCircle(0, 0, range);
		aoe.endFill();
		aoe.alpha = 0.5;
		aoe.x = troup.icone.x;
		aoe.y = troup.icone.y;

		game.board.add(aoe, Const.L_SKILL);
	}
	
	public function isActif() {
		switch(code) {
			case POISON, PIEGE, SPRINT, COUP_BOUCLIER, ATTAQUE_TOURNOYANTE, CHARGE_FRENETIC, TELEPORTATION, FIREBALL, CURSE, METAMORPHOSE, CLOACK, ASSASSINAT, DODO, SCAN :
				return cooldown <= 0;
			default : return false;
		}
		
	}
	
}