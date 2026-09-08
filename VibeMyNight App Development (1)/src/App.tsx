import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import SplashPage from "@/pages/SplashPage";
import HomePage from "@/pages/HomePage";
import EventsPage from "@/pages/EventsPage";
import EventDetailsPage from "@/pages/EventDetailsPage";
import InquiryPage from "@/pages/InquiryPage";
import SuccessPage from "@/pages/SuccessPage";
import AboutPage from "@/pages/AboutPage";
import ContactPage from "@/pages/ContactPage";
import NotFoundPage from "@/pages/NotFoundPage";
import AdminLoginPage from "@/pages/admin/AdminLoginPage";
import AdminDashboardPage from "@/pages/admin/AdminDashboardPage";
import AdminEventsPage from "@/pages/admin/AdminEventsPage";
import AdminInquiriesPage from "@/pages/admin/AdminInquiriesPage";
import AdminArtistsPage from "@/pages/admin/AdminArtistsPage";
import ArtistDetailsPage from "@/pages/ArtistDetailsPage";

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        {/* Splash */}
        <Route path="/" element={<SplashPage />} />
        <Route path="/home" element={<HomePage />} />

        {/* Customer */}
        <Route path="/events" element={<EventsPage />} />
        <Route path="/events/:id" element={<EventDetailsPage />} />
        <Route path="/inquiry" element={<InquiryPage />} />
        <Route path="/success" element={<SuccessPage />} />
        <Route path="/about" element={<AboutPage />} />
        <Route path="/contact" element={<ContactPage />} />
        <Route path="/artists/:id" element={<ArtistDetailsPage />} />

        {/* Admin */}
        <Route path="/admin" element={<Navigate to="/admin/login" replace />} />
        <Route path="/admin/login" element={<AdminLoginPage />} />
        <Route path="/admin/dashboard" element={<AdminDashboardPage />} />
        <Route path="/admin/events" element={<AdminEventsPage />} />
        <Route path="/admin/inquiries" element={<AdminInquiriesPage />} />
        <Route path="/admin/artists" element={<AdminArtistsPage />} />

        {/* 404 */}
        <Route path="*" element={<NotFoundPage />} />
      </Routes>
    </BrowserRouter>
  );
}
