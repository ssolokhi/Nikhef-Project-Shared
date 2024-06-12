//
// D. Pitzl, Jan 2011
// square plot
// .x cvsq.C

void cvsq() {
  
  //                            topleft x, y, width x, y
  TCanvas *c1 = new TCanvas("c1", "c1", 585, 246, 934, 837 );
  //                                   to get fXtoPixel = fYtoPixel

  cout << "WindowWidth  " << c1->GetWindowWidth()  << ", Ww " << c1->GetWw() << endl;
  cout << "WindowHeight " << c1->GetWindowHeight() << ", Wh " << c1->GetWh() << endl;
  cout << "FrameBorderSize " << c1->GetFrameBorderSize() << endl;
  cout << "GetBorderSize " << c1-> GetBorderSize() << endl;
  cout << "Ux " << c1->GetUxmin() << " - " << c1->GetUxmax() << endl;

  cout << "default margins:\n";
  cout << "left  " << c1->GetLeftMargin() << endl;
  cout << "bott  " << c1->GetBottomMargin() << endl;
  cout << "top   " << c1->GetTopMargin() << endl;
  cout << "right " << c1->GetRightMargin() << endl;

  c1->SetBottomMargin(0.15);
  c1->SetLeftMargin(0.15);
  c1->SetRightMargin(0.20);

  cout << "my margins:\n";
  cout << "left  " << c1->GetLeftMargin() << endl;
  cout << "bott  " << c1->GetBottomMargin() << endl;
  cout << "top   " << c1->GetTopMargin() << endl;
  cout << "right " << c1->GetRightMargin() << endl;

  cout << "PadWidth  " << c1->GetWw() << endl;
  cout << "PadHeight " << c1->GetWh() << endl;

  gPad->Update();// required

  // set styles:

  gStyle->SetTextFont(62); // 62 = Helvetica bold LaTeX

  gStyle->SetTickLength( -0.02, "x" ); // tick marks outside
  gStyle->SetTickLength( -0.02, "y" );
  gStyle->SetTickLength( -0.01, "z" );

  gStyle->SetLabelOffset( 0.022, "x" );
  gStyle->SetLabelOffset( 0.022, "y" );
  gStyle->SetLabelOffset( 0.022, "z" );

  gStyle->SetLabelFont( 62, "X" );
  gStyle->SetLabelFont( 62, "Y" );
  gStyle->SetLabelFont( 62, "Z" );

  gStyle->SetTitleOffset( 1.3, "x" );
  gStyle->SetTitleOffset( 2.0, "y" );
  gStyle->SetTitleOffset( 2.2, "z" );
  gStyle->SetTitleFont( 62, "X" );
  gStyle->SetTitleFont( 62, "Y" );
  gStyle->SetTitleFont( 62, "Z" );

  gStyle->SetTitleBorderSize(0); // no frame around global title
  gStyle->SetTitleX( 0.20 ); // global title
  gStyle->SetTitleY( 0.98 ); // global title
  gStyle->SetTitleAlign(13); // 13 = left top align

  gStyle->SetLineWidth(1);// frames
  gStyle->SetHistLineColor(4); // 4=blau
  gStyle->SetHistLineWidth(3);
  gStyle->SetHistFillColor(5); // 5=gelb
  //  gStyle->SetHistFillStyle(4050); // 4050 = half transparent
  gStyle->SetHistFillStyle(1001); // 1001 = solid

  gStyle->SetFrameLineWidth(2);

  // statistics box:

  gStyle->SetOptStat(111111);
  //gStyle->SetOptStat(10); // entries only
  gStyle->SetStatFormat("8.6g"); // more digits, default is 6.4g
  gStyle->SetStatFont(42); // 42 = Helvetica normal
  //  gStyle->SetStatFont(62); // 62 = Helvetica bold
  gStyle->SetStatBorderSize(1); // no 'shadow'

  gStyle->SetStatX(0.80);
  //gStyle->SetStatX(0.21);
  //gStyle->SetStatY(0.08);

  gStyle->SetPalette(1); // rainbow colors

  gStyle->SetOptDate();

  gStyle->SetHistMinimumZero(); // no zero suppression

  gROOT->ForceStyle();
}
