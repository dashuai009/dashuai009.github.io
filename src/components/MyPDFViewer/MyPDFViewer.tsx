// Import the main component
import { Viewer, Worker } from '@react-pdf-viewer/core';
// Import the styles
import '@react-pdf-viewer/core/lib/styles/index.css';

export default function MyPDFViewer({
  input_file
}: {
  input_file: string
}) {
  return (
    <div
      style={{
        border: '1px solid rgba(0, 0, 0, 0.3)',
        height: '250px',
      }}
    ><Worker workerUrl="https://unpkg.com/pdfjs-dist@3.4.120/build/pdf.worker.min.js">
        <Viewer fileUrl={input_file} />
      </Worker></div>

  );
}