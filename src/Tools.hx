class Tools
{
	public inline static function distance(x1:Float, x2:Float, y1:Float, y2:Float) 
	{
		return hxd.Math.distance(x2 - x1, y2 - y1);
	}

	public inline static function distanceSquare(x1:Float, x2:Float, y1:Float, y2:Float) 
	{
		return hxd.Math.distanceSq(x2 - x1, y2 - y1);
	}

	public static function split(t, startX, y, nb, w = 32, h = 21, dx = 0, dy = 0 ) {
		var tab = [];
		for (i in 0...nb) {
			tab.push(t.sub(startX*w + i*w, y*h, w, h, dx, dy));
		}
		return tab;
	}

	public static function splitAdd(t, tab, startX, y, nb, w = 32, h = 21, dx = 0, dy = 0 ) {
		for (i in 0...nb) {
			tab.push(t.sub(startX*w + i*w, y*h, w, h, dx, dy));
		}
	}

	
}

class MyPoint {
	public var x:Float;
	public var y:Float;
	public var next:MyPoint;
	
	public function new (x, y, next = null) {
		this.x = x;
		this.y = y;
		this.next = next;
	}

	public function free() {
		next = Game.cachePoint;
		Game.cachePoint = this;
	}
	
	public function length() {
		var nb = 0;
		var p = this;
		while (p.next != null) {
			p = p.next;
			nb++;
		}
		return nb;
	}
	
}



class Segment extends h2d.col.Seg {
	public var p1:h2d.col.Point;
	public var p2:h2d.col.Point;
	public var normale:h3d.Vector;
	public var bounce:Bool;
	public var isMovingRaquette:Bool;
	
	public function new(p1, p2, bounce = false) {
		super(p1, p2);
		this.p1 = p1;
		this.p2 = p2;
		var vecteur = new h3d.Vector(p1.x - p2.x, p1.y - p2.y);
		normale = new h3d.Vector(-1 * vecteur.y, vecteur.x);
		var norme = normale.length();
		normale.x /= norme;
		normale.y /= norme;
		this.bounce = bounce;
		isMovingRaquette = false;
	}

	public function toString() {
		return '[' + x + ',' + y + ', ' + dx + ',' + dy + ']';
	}
}

class Bresenham {
 
	/*
	 * Exemple d'appel :
	 * 		Tools.Bresenham.search(0, 0, -10, -13, function(ax, ay) { trace(ax, ay); return false; } );
	 * la function passée en parametre peut aussi etre une condition d'arret en retournant true.
	*/
	inline static public function search( x1 : Float, y1 : Float, x2 : Float, y2 : Float, callb : Float -> Float -> Bool ) {

		var dx = x2 - x1;
		var dy = y2 - y1;
		
		if (dx != 0) {
			if( dx > 0) {
				if (dy != 0) {
					if( dy > 0) {
					  // vecteur oblique dans le 1er quadran
						if( dx >= dy) {
							// vecteur diagonal ou oblique proche de l’horizontale, dans le 1er octant
							var e = dx; // e est positif
							dx = dx * 2 ; 
							dy = dy * 2 ;  
							
							while (true) {  // déplacements horizontaux
								if ( callb(x1, y1) ) break;
								x1++;
								//if (x1 == x2) break;
								if (x1 >= x2) break;
								e = e - dy;
								if (e < 0 ) {
									y1++;  // déplacement diagonal
									e = e + dx ;
								}
							}
						}
						else {
							// vecteur oblique proche de la verticale, dans le 2nd octant
							var e = dy; // e est positif
							dy  = dy * 2;
							dx = dx * 2 ;  
							while(true) { // déplacements verticaux
								if ( callb(x1, y1) ) break;
								y1++;
								if (y1 == y2) break ;
								e = e - dx;
								if (e < 0) {
									x1++;  // déplacement diagonal
									e = e + dy ;
								}
							}
						}
					}
					else { // dy < 0 (et dx > 0)
						// vecteur oblique dans le 4e cadran
						if( dx >= -dy ) {
							// vecteur diagonal ou oblique proche de l’horizontale, dans le 8e octant
							var e = dx; // e est positif
							dx = dx * 2;
							dy = dy * 2 ;  
							while(true) {  // déplacements horizontaux
								if ( callb(x1, y1) ) break;
								x1++;
								if (x1 == x2) break;
								e = e + dy;
								if(e < 0) {
									y1--; // déplacement diagonal
									e = e + dx ;
								}
							}
						}
						else { 
							// vecteur oblique proche de la verticale, dans le 7e octant
							var e = dy; // e est négatif
							dy = dy * 2; 
							dx = dx * 2 ; 
							while(true) { // déplacements verticaux
								if ( callb(x1, y1) ) break;
								y1--;
								if (y1 == y2) break;
								e = e + dx;
								if(e > 0) {
									x1++;  // déplacement diagonal
									e = e + dy;
								}
							}
						}
					}
				}
				else { // dy = 0 (et dx > 0)
						// vecteur horizontal vers la droite
					do 	{
						if ( callb(x1, y1) ) break;
						x1++;
					}
					while (x1 != x2);
				}
			}
			else { // dx < 0
				if ( dy != 0 ) {
					if( dy > 0) { // vecteur oblique dans le 2nd quadran
						if( -dx >= dy) { // vecteur diagonal ou oblique proche de l’horizontale, dans le 4e octant
							var e = dx; // e est négatif
							dx = dx * 2;
							dy = dy * 2; 
							while(true) { // déplacements horizontaux
								if ( callb(x1, y1) ) break;
								x1--;
								if ( x1 == x2 ) break;
								e = e + dy;
								if (e >= 0 ) {
									y1++;  // déplacement diagonal
									e = e + dx ;
								}
							}
						}
						else { // vecteur oblique proche de la verticale, dans le 3e octant
							var e = dy; // e est positif
							dy = dy * 2;
							dx = dx * 2 ;  
							while(true) { // déplacements verticaux
								if ( callb(x1, y1) ) break;
								y1++;
								if (y1 == y2) break;
								e = e + dx;
								if (e <= 0 ) {
									x1--;  // déplacement diagonal
									e = e + dy ;
								}
							}
						}
					}
					else { // dy < 0 (et dx < 0)
						// vecteur oblique dans le 3e cadran
						  
						if( dx <= dy ) { // vecteur diagonal ou oblique proche de l’horizontale, dans le 5e octant
							var e = dx; // e est négatif
							dx = dx * 2;
							dy = dy * 2 ; 
							while(true) { // déplacements horizontaux
								if ( callb(x1, y1) ) break;
								x1--;
								if ( x1 == x2 ) break;
								e = e - dy;
								if (e >= 0) {
									y1--;  // déplacement diagonal
									e = e + dx ;
								}
							}
						}
						else { // vecteur oblique proche de la verticale, dans le 6e octant
							var e = dy; // e est négatif
							dy = dy * 2; 
							dx = dx * 2 ; 
							while(true) { // déplacements verticaux
								if ( callb(x1, y1) ) break;
								y1--;
								if ( y1 == y2) break;
								e = e - dx;
								if (e >= 0) {
									x1--;  // déplacement diagonal
									e = e + dy ;
								}
							}
						}
					}
				}
				else { // dy = 0 (et dx < 0)
					// vecteur horizontal vers la gauche
					do {
						if ( callb(x1, y1) ) break;
						x1--;
					}
					while( x1 != x2 );
				}
			}
		}
		else { // dx = 0
			if ( dy != 0 ) {
				if ( dy > 0 ) { // vecteur vertical croissant
						do {
						if ( callb(x1, y1) ) break;
						  y1++;
						}
						while(y1 != y2) ;
				}
				else { // dy < 0 (et dx = 0)
					do { // vecteur vertical décroissant
						if ( callb(x1, y1) ) break;
						y1--;
					}
					while ( y1 != y2 );
				}
			}
		}
	}
}