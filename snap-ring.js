function main() {
    const hidef = false;
    
    const ring = getRing(hidef);
    const rod = getRod(hidef);
    
    return [ring, rod];
}

function getRing(hidef) {
    const roundOptions = {
        ri: 1,
        fni: hidef ? 128 : 16,
        roti: 0,
        ro: 16,
        fno: hidef ? 256 : 32,
    };
    const squareOptions = {
        ri: 1.415,
        fni: 4,
        roti: 45,
        ro: 16,
        fno: hidef ? 256 : 32,
    };
    
    const round = torus(roundOptions);
    const square = torus(squareOptions);
    
    const top = translate([0,0,6], round);
    const middle5 = translate([0,0,5], square);
    const middle4 = translate([0,0,4], square);
    const middle3 = translate([0,0,3], square);
    const middle2 = translate([0,0,2], square);
    const bottom = translate([0,0,1], round);
    
    return union(bottom, middle2, middle3, middle4, middle5, top);
}

function getRod(hidef) {
    
}
