# StudyStack
🎵 *My StudyStack Brings All the A's to The Yard* 🎵

A marketplace platform for students to upload, sell, and intelligently search study materials using AI-powered document analysis.

## 🎯 Overview

StudyStack is a student-focused platform that combines document management with intelligent search capabilities and social media features. Similar to Substack, students can upload their study materials, build followings, engage with their audience, and leverage AI to get intelligent answers from their document collections. It's a social marketplace where students can monetize their content while building communities around their expertise.

## 🛠 Tech Stack

- **Frontend**: Next.js 14, TypeScript, Tailwind CSS
- **Backend API**: Ruby on Rails (API mode)
- **Database**: PostgreSQL
- **Search Engine**: Elasticsearch
- **AI/ML**: Python with RAG (Retrieval-Augmented Generation)
- **File Storage**: Local storage (with S3 migration planned)
- **AI Provider**: OpenAI/Anthropic APIs
- **Payments**: Stripe for content monetization
- **Streaming**: WebRTC for live study sessions

## 📁 Project Structure

```
studystack/
├── backend/          # Rails API server
├── frontend/         # Next.js React application
├── python-service/   # Python AI/ML service (planned)
└── docs/            # Documentation
```

## 🚀 Features

### Current Features
- [x] User authentication (register/login)
- [x] Secure JWT-based sessions
- [x] Document upload system
- [x] RESTful API endpoints

### Planned Features
- [ ] Document marketplace with pricing
- [ ] Elasticsearch integration for document search
- [ ] AI-powered document Q&A using RAG
- [ ] Document preview and viewer
- [ ] User profiles and ratings
- [ ] Payment processing with Stripe
- [ ] Advanced search filters

#### Streaming Features (Twitch-inspired)
- [ ] Live study session broadcasting
- [ ] Real-time video streaming with WebRTC
- [ ] Chat during live streams
- [ ] Stream recording and playback
- [ ] Follower notifications for live sessions
- [ ] Study room creation and management
- [ ] Screen sharing for tutorials
- [ ] Interactive whiteboards during streams
- [ ] Monetized streams with tips/donations
- [ ] Scheduled study sessions

#### Social Media Features (Substack-inspired)
- [ ] User following/followers system
- [ ] Content feed and timeline
- [ ] Comments and discussions on documents
- [ ] Likes and reactions
- [ ] Share functionality
- [ ] Notifications system
- [ ] Creator profiles with bio and links
- [ ] Subscription tiers for premium content
- [ ] Email newsletters for followers
- [ ] Analytics dashboard for creators
- [ ] Trending content discovery
- [ ] Tags and categories for content organization

#### Payment & Monetization
- [ ] Stripe integration for payments
- [ ] Creator earnings dashboard
- [ ] Subscription management
- [ ] One-time document purchases
- [ ] Stream donations and tips
- [ ] Revenue sharing system
- [ ] Payout scheduling
- [ ] Tax document generation

## 🔧 Installation & Setup

### Prerequisites
- Node.js 18+
- Ruby 3.0+
- PostgreSQL 12+
- Python 3.8+
- Elasticsearch 8.0+

### Backend Setup (Rails)
```bash
cd backend
bundle install
rails db:create db:migrate db:seed
rails server -p 3001
```

### Frontend Setup (Next.js)
```bash
cd frontend
npm install
npm run dev
```

### Python Service Setup (Coming Soon)
```bash
cd python-service
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

## 🌐 API Endpoints

### Authentication
- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User login
- `DELETE /api/auth/logout` - User logout

### Documents
- `GET /api/documents` - List user documents
- `POST /api/documents` - Upload new document
- `GET /api/documents/:id` - Get document details
- `DELETE /api/documents/:id` - Delete document

### Search
- `GET /api/search` - Search documents
- `POST /api/search/query` - AI-powered query with RAG

### Social Features
- `POST /api/users/:id/follow` - Follow a user
- `DELETE /api/users/:id/follow` - Unfollow a user
- `GET /api/users/:id/followers` - Get user followers
- `GET /api/users/:id/following` - Get users being followed
- `GET /api/feed` - Get personalized content feed
- `POST /api/documents/:id/like` - Like a document
- `POST /api/documents/:id/comments` - Add comment to document
- `GET /api/documents/:id/comments` - Get document comments
- `GET /api/notifications` - Get user notifications
- `POST /api/subscriptions` - Subscribe to creator
- `GET /api/trending` - Get trending content

### Streaming Features
- `POST /api/streams` - Create a new stream
- `GET /api/streams/live` - Get currently live streams
- `GET /api/streams/:id` - Get stream details
- `POST /api/streams/:id/join` - Join a stream
- `POST /api/streams/:id/chat` - Send chat message
- `GET /api/streams/:id/chat` - Get chat messages
- `POST /api/streams/:id/donate` - Send donation/tip
- `GET /api/users/:id/streams` - Get user's streams

### Payment Features
- `POST /api/payments/setup-intent` - Create Stripe setup intent
- `POST /api/payments/subscribe` - Create subscription
- `POST /api/payments/purchase` - One-time purchase
- `GET /api/payments/earnings` - Get creator earnings
- `POST /api/payments/payout` - Request payout
- `GET /api/payments/transactions` - Get payment history

## 🔐 Environment Variables

### Backend (.env)
```env
DATABASE_URL=postgresql://username:password@localhost/studystack_development
JWT_SECRET=your_jwt_secret_key
RAILS_ENV=development
```

### Frontend (.env.local)
```env
NEXT_PUBLIC_API_URL=http://localhost:3001
```

### Python Service (.env)
```env
OPENAI_API_KEY=your_openai_api_key
ELASTICSEARCH_URL=http://localhost:9200
```

### Stripe (.env)
```env
STRIPE_PUBLISHABLE_KEY=pk_test_your_stripe_publishable_key
STRIPE_SECRET_KEY=sk_test_your_stripe_secret_key
STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret
```

## 🧪 Testing

### Backend Tests
```bash
cd backend
rails test
```

### Frontend Tests
```bash
cd frontend
npm test
```

## 📈 Performance Considerations

- **File Upload**: Chunked uploads for large documents
- **Search**: Elasticsearch indexing with optimized mappings
- **AI Queries**: Caching for frequently asked questions
- **Database**: Proper indexing on search fields
- **Social Feed**: Efficient timeline generation with Redis caching
- **Notifications**: Real-time updates with WebSockets
- **Content Delivery**: CDN for static assets and documents
- **Streaming**: WebRTC optimization for low-latency video
- **Payment Processing**: Secure Stripe integration with webhooks

## 🚀 Deployment

### Production Stack
- **Frontend**: Vercel/Netlify
- **Backend**: Heroku/Railway
- **Database**: Heroku Postgres/AWS RDS
- **Search**: Elastic Cloud
- **File Storage**: AWS S3
- **Python Service**: AWS Lambda/Google Cloud Functions
- **Caching**: Redis Cloud
- **Email**: SendGrid/Mailgun
- **Real-time**: WebSocket service (Socket.io/Action Cable)
- **Payments**: Stripe
- **Streaming**: AWS IVS/Agora.io/Daily.co for WebRTC

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Contact

- GitHub: [@robynmaya](https://github.com/robynmaya)
- Project Link: [https://github.com/robynmaya/studystack](https://github.com/robynmaya/studystack)

---

**Note**: This is an active development project. Features and architecture may change as development progresses.
