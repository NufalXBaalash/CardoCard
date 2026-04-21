from supabase import create_client, Client
from app.services.config import settings


class SupabaseService:

    def __init__(self):
        self.client: Client = create_client(
            settings.SUPABASE_URL,
            settings.SUPABASE_KEY
        )

    def get_unprocessed_reports(self, user_id: str):
        """Fetch medical records for a patient that haven't been analyzed yet."""
        try:
            response = self.client.table("medical_records") \
                .select("id, diagnosis, treatment, notes, date") \
                .eq("patient_id", user_id) \
                .execute()

            results = []
            ids = []

            for record in response.data:
                text_parts = []
                if record.get("diagnosis"):
                    text_parts.append(f"Diagnosis: {record['diagnosis']}")
                if record.get("treatment"):
                    text_parts.append(f"Treatment: {record['treatment']}")
                if record.get("notes"):
                    text_parts.append(f"Notes: {record['notes']}")

                text = "\n".join(text_parts)
                if text.strip():
                    results.append(text)
                    ids.append(record["id"])

            return results, ids

        except Exception as e:
            print(f"[Supabase] ERROR fetching reports: {e}")
            return [], []

    def get_patient_profile(self, user_id: str):
        """Fetch patient profile data."""
        try:
            response = self.client.table("profiles") \
                .select("*") \
                .eq("id", user_id) \
                .maybe_single() \
                .execute()
            return response.data if response.data else {}
        except Exception as e:
            print(f"[Supabase] ERROR fetching profile: {e}")
            return {}

    def get_available_doctors(self, specialty: str = None):
        """Fetch doctors, optionally filtered by specialty."""
        try:
            query = self.client.table("doctors").select("id, name, specialty, price, rating")
            if specialty:
                query = query.eq("specialty", specialty)
            response = query.execute()
            return response.data
        except Exception as e:
            print(f"[Supabase] ERROR fetching doctors: {e}")
            return []

    def get_doctor_slots(self, doctor_id: str, day_of_week: int):
        """Fetch available time slots for a doctor on a specific day."""
        try:
            # Get availability
            avail_response = self.client.table("doctor_availability") \
                .select("start_time, end_time") \
                .eq("doctor_id", doctor_id) \
                .eq("day_of_week", day_of_week) \
                .eq("is_available", True) \
                .execute()

            return avail_response.data
        except Exception as e:
            print(f"[Supabase] ERROR fetching slots: {e}")
            return []

    def upload_report(self, patient_id: str, doctor_id: str, data: dict):
        """Insert a new medical record."""
        try:
            record = {
                "patient_id": patient_id,
                "doctor_id": doctor_id,
                "date": data.get("date"),
                "diagnosis": data.get("diagnosis", ""),
                "treatment": data.get("treatment", ""),
                "notes": data.get("notes", ""),
            }
            response = self.client.table("medical_records").insert(record).execute()
            return response.data
        except Exception as e:
            print(f"[Supabase] ERROR uploading report: {e}")
            return None
