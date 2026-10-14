import { jsPDF } from 'jspdf';
import QRCode from 'qrcode';
import { Passager, Reservation } from './models';

/**
 * Billet PDF identique à celui de l'application mobile (mes_billets_screen.dart › _telechargerPdf) :
 * A4, marges 40 pt, bandeau vert TamBour, infos passager à gauche, QR d'embarquement à droite.
 * Une page par passager.
 */
const VERT: [number, number, number] = [15, 74, 59];      // #0F4A3B
const OR: [number, number, number] = [242, 169, 59];       // #F2A93B (logo)
const ENCRE: [number, number, number] = [26, 26, 26];      // #1A1A1A
const GRIS_300: [number, number, number] = [224, 224, 224];
const GRIS_600: [number, number, number] = [117, 117, 117];
const GRIS: [number, number, number] = [158, 158, 158];

const MARGE = 40;
const LARGEUR = 595.28;

function dateHeure(iso: string): string {
  const d = new Date(iso);
  const z = (n: number) => String(n).padStart(2, '0');
  return `${z(d.getDate())}/${z(d.getMonth() + 1)}/${d.getFullYear()} ${z(d.getHours())}:${z(d.getMinutes())}`;
}

function montant(n: number): string {
  return Math.round(n).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ' ');
}

/** Flèche « → » dessinée (la police standard du PDF n'a pas ce glyphe). */
function fleche(doc: jsPDF, cx: number, cy: number): void {
  doc.setDrawColor(...OR); doc.setFillColor(...OR); doc.setLineWidth(2.4);
  doc.line(cx - 10, cy, cx + 5, cy);
  doc.triangle(cx + 11, cy, cx + 3, cy - 6, cx + 3, cy + 6, 'F');
}

function coche(doc: jsPDF, x: number, y: number): void {
  doc.setDrawColor(...VERT); doc.setLineWidth(1.6);
  doc.lines([[3, 3], [6, -7]], x, y - 3, [1, 1], 'S', false);
}

/** QR vectoriel : yeux verts, modules #1A1A1A, comme le QrPainter de l'application. */
function dessinerQr(doc: jsPDF, data: string, x: number, y: number, taille: number): void {
  const qr = QRCode.create(data, { errorCorrectionLevel: 'L' });
  const n = qr.modules.size;
  const m = taille / n;
  const estOeil = (r: number, c: number) => (r < 7 && c < 7) || (r < 7 && c >= n - 7) || (r >= n - 7 && c < 7);
  for (let r = 0; r < n; r++) {
    for (let c = 0; c < n; c++) {
      if (!qr.modules.get(r, c)) continue;
      doc.setFillColor(...(estOeil(r, c) ? VERT : ENCRE));
      doc.rect(x + c * m, y + r * m, m + 0.05, m + 0.05, 'F');
    }
  }
}

function pageBillet(doc: jsPDF, r: Reservation, p: Passager, numero: number, total: number, logo: string | null): void {
  const t = r.trajet_info;
  const l = LARGEUR - 2 * MARGE;

  // ── En-tête vert ───────────────────────────────────────────────────────────
  const hTete = 124;
  doc.setFillColor(...VERT);
  doc.roundedRect(MARGE, MARGE, l, hTete, 12, 12, 'F');
  const xi = MARGE + 20, xd = MARGE + l - 20;
  doc.setFont('helvetica', 'bold'); doc.setFontSize(24); doc.setTextColor(255, 255, 255);
  // Symbole du logo (30 pt de haut) puis le nom, comme dans l'application
  const decalage = logo ? 21.3 + 7 : 0;
  if (logo) doc.addImage(logo, 'PNG', xi, MARGE + 17, 21.3, 30);
  doc.text('TamBour', xi + decalage, MARGE + 20 + 22);
  if (total > 1) {
    const libelle = `Billet ${numero}/${total}`;
    doc.setFontSize(11);
    const lb = doc.getTextWidth(libelle) + 20;
    doc.setFillColor(255, 255, 255);
    doc.roundedRect(xd - lb, MARGE + 22, lb, 20, 10, 10, 'F');
    doc.setTextColor(...VERT);
    doc.text(libelle, xd - lb / 2, MARGE + 22 + 14, { align: 'center' });
  }
  const yVilles = MARGE + 20 + 29 + 16 + 18;
  doc.setFontSize(20); doc.setTextColor(255, 255, 255);
  doc.text(t.depart, xi, yVilles);
  doc.text(t.arrivee, xd, yVilles, { align: 'right' });
  doc.setFont('helvetica', 'normal'); doc.setFontSize(9);
  doc.text('DÉPART', xi, yVilles + 13);
  doc.text('ARRIVÉE', xd, yVilles + 13, { align: 'right' });
  fleche(doc, MARGE + l / 2, yVilles - 7);

  // ── Infos passager ─────────────────────────────────────────────────────────
  const yCorps = MARGE + hTete + 24;
  // Prix du billet, hors frais de service (montant_total pour les réservations antérieures aux frais)
  const billets = r.montant_billets || r.montant_total;
  const prixParPassager = r.passagers.length ? billets / r.passagers.length : billets;
  const infos: [string, string][] = [
    ['Référence', p.billet?.reference_billet ?? `${r.reference}-P${numero}`],
    ['Passager', `${p.prenom} ${p.nom}`],
    ['Téléphone', p.telephone || '—'],
    ...(p.email ? [['Email', p.email] as [string, string]] : []),
    ['Siège', p.siege_numero || '—'],
    ['Date/Heure', dateHeure(t.heure_depart)],
    ['Compagnie', t.compagnie],
    ['Montant', `${montant(prixParPassager)} FCFA`],
    ['Statut', 'Confirmé'],
  ];
  let y = yCorps;
  for (const [label, valeur] of infos) {
    doc.setFont('helvetica', 'bold'); doc.setFontSize(9); doc.setTextColor(...GRIS_600);
    doc.text(label, MARGE, y + 8);
    doc.setFontSize(12); doc.setTextColor(0, 0, 0);
    doc.text(valeur, MARGE, y + 8 + 2 + 12);
    if (label === 'Statut') coche(doc, MARGE + doc.getTextWidth(valeur) + 6, y + 8 + 2 + 8);
    y += 36;
  }

  // ── QR d'embarquement ──────────────────────────────────────────────────────
  const cote = 140 + 16;
  const xq = MARGE + l - cote;
  doc.setDrawColor(...GRIS_300); doc.setLineWidth(1);
  doc.roundedRect(xq, yCorps, cote, cote, 8, 8, 'S');
  if (p.billet?.qr_data) dessinerQr(doc, p.billet.qr_data, xq + 8, yCorps + 8, 140);
  doc.setFont('helvetica', 'normal'); doc.setFontSize(8); doc.setTextColor(...GRIS);
  doc.text("QR d'embarquement", xq + cote / 2, yCorps + cote + 6 + 8, { align: 'center' });

  // ── Pied ───────────────────────────────────────────────────────────────────
  const yPied = Math.max(y, yCorps + cote + 20) + 20;
  doc.setDrawColor(...GRIS_300); doc.setLineWidth(1);
  doc.line(MARGE, yPied, MARGE + l, yPied);
  doc.setFontSize(9); doc.setTextColor(...GRIS);
  doc.text('Ce billet est nominatif et non transférable.', MARGE, yPied + 8 + 10);
  doc.text('Support : support@tambour.ci', MARGE, yPied + 8 + 22);
}

async function chargerLogo(): Promise<string | null> {
  try {
    const blob = await (await fetch('assets/marque/symbole-clair.png')).blob();
    return await new Promise<string>((ok, ko) => {
      const lecteur = new FileReader();
      lecteur.onload = () => ok(lecteur.result as string); lecteur.onerror = ko;
      lecteur.readAsDataURL(blob);
    });
  } catch { return null; }
}

/** Génère et télécharge le PDF : tous les passagers, ou un seul si `passagerId` est fourni. */
export async function telechargerBilletsPdf(r: Reservation, passagerId?: string): Promise<void> {
  const logo = await chargerLogo();
  const doc = new jsPDF({ unit: 'pt', format: 'a4' });
  const tous = [...r.passagers].sort((a, b) => a.ordre - b.ordre);
  const cibles = passagerId ? tous.filter(p => p.id === passagerId) : tous;
  cibles.forEach((p, i) => {
    if (i > 0) doc.addPage();
    pageBillet(doc, r, p, tous.indexOf(p) + 1, tous.length, logo);
  });
  doc.setProperties({ title: `Billet TamBour ${r.reference}`, author: 'TamBour' });
  const suffixe = passagerId && cibles[0] ? `-P${tous.indexOf(cibles[0]) + 1}` : '';
  doc.save(`TamBour-${r.reference}${suffixe}.pdf`);
}
