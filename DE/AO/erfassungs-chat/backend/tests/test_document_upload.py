import tempfile
import unittest
from pathlib import Path

from app.config import Settings
from app.document_upload import UploadRejected, store_upload_mock


class TestDocumentUpload(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.settings = Settings(upload_max_bytes=1024)

    def tearDown(self):
        self.tmp.cleanup()

    def test_valid_pdf_accepted(self):
        result = store_upload_mock(
            filename="satzung.pdf",
            content_type="application/pdf",
            data=b"%PDF-1.4 ...",
            document_type="Gesellschaftsvertrag",
            settings=self.settings,
            mock_upload_dir=self.tmp.name,
        )
        self.assertTrue(result.file_link.startswith("mock://"))
        self.assertTrue((Path(self.tmp.name)).exists())

    def test_disallowed_extension_rejected(self):
        with self.assertRaises(UploadRejected) as ctx:
            store_upload_mock(
                filename="makro.docm",
                content_type="application/vnd.ms-word.document.macroEnabled.12",
                data=b"irrelevant",
                document_type="Sonstiges",
                settings=self.settings,
                mock_upload_dir=self.tmp.name,
            )
        self.assertEqual(ctx.exception.reason, "type_not_allowed")

    def test_too_large_rejected(self):
        with self.assertRaises(UploadRejected) as ctx:
            store_upload_mock(
                filename="gross.pdf",
                content_type="application/pdf",
                data=b"x" * 2048,
                document_type="Sonstiges",
                settings=self.settings,
                mock_upload_dir=self.tmp.name,
            )
        self.assertEqual(ctx.exception.reason, "too_large")

    def test_empty_file_rejected(self):
        with self.assertRaises(UploadRejected) as ctx:
            store_upload_mock(
                filename="leer.pdf",
                content_type="application/pdf",
                data=b"",
                document_type="Sonstiges",
                settings=self.settings,
                mock_upload_dir=self.tmp.name,
            )
        self.assertEqual(ctx.exception.reason, "empty_file")


if __name__ == "__main__":
    unittest.main()
