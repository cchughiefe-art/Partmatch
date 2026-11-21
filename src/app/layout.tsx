import type { Metadata } from "next";
import "./globals.css";
export const metadata:Metadata = {title:"PartMatch — Phone Screen Compatibility",description:"Search phone LCD and display compatibility by device name, model code, or screen part number."};
export default function RootLayout({children}:{children:React.ReactNode}) {
 return <html lang="en"><body>{children}</body></html>;
}
