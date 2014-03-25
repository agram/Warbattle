import Common;

class SkillZone
{
	var game:Game;
	var w:Int;
	var h:Int;
	public var skill:Skill;
	var bg: h2d.Bitmap;
	public var bgSelected: h2d.Bitmap;
	var texte: h2d.Text;
	var font:h2d.Font;
	
	var anim:h2d.Anim;

	public function new(numero:Int) 
	{
		game = Game.inst;
		
		font = Res.Minecraftia.build(8, { antiAliasing : false } );
		texte = new h2d.Text(font);
		texte.color = new h3d.Vector();
		texte.x = 24;
		texte.y = 6;
		
		w = 200;
		h = 25;
		if(numero == 1) {
			var fg = h2d.Tile.fromColor(0x80FF0000, w, h);
			bg = new h2d.Bitmap(fg, game.boardUi);
			bg.x = Const.BASE_WIDTH / 2 - w / 2;
			bg.y = Const.BASE_HEIGHT - h;
			
			var fg = h2d.Tile.fromColor(0x80FFFFFF, w - 25, h - 4);
			bgSelected = new h2d.Bitmap(fg, game.boardUi);
			bgSelected.x = Const.BASE_WIDTH / 2 - w / 2 + 22;
			bgSelected.y = Const.BASE_HEIGHT - h + 2;
			bgSelected.visible = false;
			
			anim = new h2d.Anim(game.gfx.message.z, bg);
			anim.x = 2;
			anim.y = 5;
			anim.colorKey = 0xFFFFFFFF;
		}
		else if(numero == 2) {
			var fg = h2d.Tile.fromColor(0x8000FF00, w, h);
			bg = new h2d.Bitmap(fg, game.boardUi);
			bg.x = Const.BASE_WIDTH / 2 + w / 2;
			bg.y = Const.BASE_HEIGHT - h;

			var fg = h2d.Tile.fromColor(0x80FFFFFF, w - 25, h - 4);
			bgSelected = new h2d.Bitmap(fg, game.boardUi);
			bgSelected.x = Const.BASE_WIDTH / 2 + w / 2 + 22;
			bgSelected.y = Const.BASE_HEIGHT - h + 2;
			bgSelected.visible = false;

			anim = new h2d.Anim(game.gfx.message.e, bg);
			anim.x = 2;
			anim.y = 5;
			anim.colorKey = 0xFFFFFFFF;
		}
		else {
			var fg = h2d.Tile.fromColor(0x8000FF00, w, h);
			bg = new h2d.Bitmap(fg, game.boardUi);
			bg.x = Const.BASE_WIDTH / 2 - 1.5 * w + 2;
			bg.y = Const.BASE_HEIGHT - h;

			var fg = h2d.Tile.fromColor(0x80FFFFFF, w - 25, h - 4);
			bgSelected = new h2d.Bitmap(fg, game.boardUi);
			bgSelected.x = Const.BASE_WIDTH / 2 - 1.5 * w+ 22;
			bgSelected.y = Const.BASE_HEIGHT - h + 2;
			bgSelected.visible = false;

			anim = new h2d.Anim(game.gfx.message.a, bg);
			anim.x = 2;
			anim.y = 5;
			anim.colorKey = 0xFFFFFFFF;
			
			texte.text = "Attaque !";
			bg.addChild(texte);
		}
		
		skill = null;
		
		var interactive = new h2d.Interactive(w, h, bg);
		interactive.onClick = function (_) {
			if (skill == null || skill.troup.dead || skill.troup.isFourmi() || skill.troup.isStun() || !skill.isActif() ) return;
			if (game.modeAttackMove) game.deactivateAttackMove();
			skill.activate();
			switch(skill.code) {
				case ATTAQUE_TOURNOYANTE, COUP_BOUCLIER, CHARGE_FRENETIC, SCAN :
				default : activated();
			}
			
		}
				
	}
	
	public function show(skill:Skill, timer = false) {
		bg.removeChild(texte);
		this.skill = skill;
		texte.text = 
			switch(skill.code) {
				case POISON: "Flèche Empoisonnée";
				case PIEGE: "Piege à Loup";
				case TIR_BARRAGE: "Tir de Barrage";
				case SPRINT: "Sprint";
				case LEVER_BOUCLIER: "Boucliers Levés";
				case COUP_BOUCLIER: "Coup de Bouclier";
				case FORMATION_SERREE: "Formation Serrée";
				case ATTAQUE_TOURNOYANTE: "Cleave";
				case CHARGE_FRENETIC: "Charge Frénétique";
				case BERSERK: "Berzeker";
				case TELEPORTATION: "Téléportation";
				case FIREBALL: "Boule de Feu";
				case CURSE: "Malédiction";
				case METAMORPHOSE: "Métamorphose";
				case CLOACK: "Camouflage";
				case ASSASSINAT: "Assassinat";
				case MINDCONTROL: "Control Mental";
				case DODO: "Sommeil";
				case SCAN: "6ième Sens";
				case POWER_AURA: "Aura de Puissance";
				case RESURECT: "Résurection";
			};
		if (timer) texte.text += ' <- ' + skill.cooldown;
		texte.alpha = (skill.isActif()) ? 1 : 0.5;
		switch( skill.code) {
			case TIR_BARRAGE, LEVER_BOUCLIER, FORMATION_SERREE, POWER_AURA: 
				texte.alpha = 0.5;
			default:
		}
		bg.addChild(texte);
	}
	
	public function activated() {
		bgSelected.visible = true;
	}
	
	public function deactivated() {
		bgSelected.visible = false;
	}
	
	public function hide() {
		bg.removeChild(texte);
		if(skill != null) skill.closeAOE();
		skill = null;
	}
	
	static public function hideAll() {
		for (i in 0...2) {
			var s = Game.inst.skillZones[i];
			s.deactivated();
			s.hide();
		}
		
	}
}