# Unified SSO Implementation Plan for QXLI Monorepo

## Current Architecture Analysis

### Applications Currently Running
1. **qxli-ui** (demo.qxli.com) - Main UI application on port 8888
   - Tech Stack: Svelte/SvelteKit frontend, FastAPI backend
   - Authentication: Built-in auth system with JWT tokens, OAuth support, LDAP integration
   - Features: User management, API keys, trusted headers auth

2. **Langflow** (flow.qxli.com) - AI workflow builder on port 7860  
   - Tech Stack: Python FastAPI backend, React frontend
   - Authentication: Built-in superuser system (admin/VGzjw7TENdzNQC4W)
   - Features: Flow builder, AI agent management

3. **n8n** (agents.qxli.com) - Workflow automation on port 5678
   - Tech Stack: Node.js/TypeScript
   - Authentication: Built-in user system
   - Features: Workflow automation, integrations

4. **Supporting Services**:
   - Ollama (port 11434) - LLM inference
   - Qdrant (port 6333) - Vector database
   - GPT-Researcher (commented out) - Research agent

### Current Authentication Mechanisms

1. **qxli-ui**: 
   - JWT token-based authentication
   - OAuth providers support
   - LDAP integration
   - API key authentication
   - Trusted header authentication
   - Session management with cookies

2. **Langflow**:
   - Environment-based superuser credentials
   - Session-based authentication
   - User registration disabled by default

3. **n8n**:
   - Built-in user management
   - Session-based authentication

## Feasibility Assessment: **YES, IT'S POSSIBLE**

## Unified SSO Solution Architecture

### Solution Overview
Implement a **reverse proxy-based SSO gateway** using qxli-ui as the central authentication service, with path-based routing on a single domain.

### Proposed Architecture

```
Single Domain (qxli.com)
├── / → qxli-ui (main app + auth provider)
├── /flow → Langflow (protected)
├── /agents → n8n (protected) 
├── /api/auth → Central auth endpoints
└── /api/proxy → Service proxy endpoints
```

### Technical Implementation Strategy

#### Phase 1: Central Authentication Service
1. **Enhance qxli-ui as SSO Provider**
   - Extend existing JWT auth to support cross-service tokens
   - Add service-specific scopes and permissions
   - Implement OAuth2/OpenID Connect server functionality
   - Create centralized user management dashboard

2. **Session Management**
   - Single sign-on session cookies for qxli.com domain
   - JWT tokens for API access across services
   - Session sharing between services via secure cookie domain

#### Phase 2: Service Integration
1. **Langflow Integration**
   - Disable built-in authentication
   - Configure to accept JWT tokens from qxli-ui
   - Implement authorization middleware for Langflow API endpoints
   - Create user context passing mechanism

2. **n8n Integration** 
   - Configure n8n to use external authentication
   - Implement JWT validation middleware
   - Map qxli-ui users to n8n user contexts
   - Handle workflow permissions based on central user roles

#### Phase 3: Unified Routing
1. **Enhanced Nginx Configuration**
   ```nginx
   server {
       listen 443 ssl;
       server_name qxli.com;
       
       # Main app
       location / {
           proxy_pass http://qxli-ui:8080;
           include /etc/nginx/auth_headers.conf;
       }
       
       # Langflow with auth check
       location /flow {
           auth_request /auth-check;
           rewrite ^/flow(.*)$ $1 break;
           proxy_pass http://langflow:7860;
           include /etc/nginx/proxy_headers.conf;
       }
       
       # n8n with auth check  
       location /agents {
           auth_request /auth-check;
           rewrite ^/agents(.*)$ $1 break;
           proxy_pass http://n8n:5678;
           include /etc/nginx/proxy_headers.conf;
       }
       
       # Auth validation endpoint
       location = /auth-check {
           internal;
           proxy_pass http://qxli-ui:8080/api/auth/validate;
           proxy_pass_request_body off;
           proxy_set_header Content-Length "";
           proxy_set_header X-Original-URI $request_uri;
       }
   }
   ```

#### Phase 4: Single Docker Deployment

1. **Unified Docker Compose Structure**
   ```yaml
   services:
     # Main SSO-enabled services
     qxli-unified:
       build: 
         context: .
         dockerfile: Dockerfile.unified
       ports:
         - "8080:8080"  # Main app
         - "7860:7860"  # Langflow
         - "5678:5678"  # n8n
       environment:
         - SSO_ENABLED=true
         - JWT_SECRET_KEY=${JWT_SECRET_KEY}
       
     # Reverse proxy with SSO
     nginx-sso:
       build: ./nginx-sso
       ports:
         - "443:443"
       depends_on:
         - qxli-unified
   ```

2. **Multi-Stage Dockerfile Strategy**
   ```dockerfile
   # Stage 1: qxli-ui with SSO enhancements
   FROM node:18 as qxli-ui-build
   WORKDIR /app/qxli-ui
   COPY qxli-ui/ .
   RUN npm install && npm run build
   
   # Stage 2: Langflow with auth disabled
   FROM python:3.11 as langflow-build  
   WORKDIR /app/langflow
   COPY qxli-flow/ .
   RUN pip install -e .
   
   # Stage 3: n8n with external auth
   FROM node:18 as n8n-build
   RUN npm install -g n8n
   
   # Final unified stage
   FROM ubuntu:22.04
   # Copy all built applications
   # Configure supervisord for process management
   # Set up service discovery and auth integration
   ```

### Implementation Benefits

1. **User Experience**
   - Single login for all services
   - No subdomain navigation required
   - Consistent UI/UX across all tools
   - Centralized user management

2. **Security**
   - Centralized authentication and authorization
   - Single point of security policy enforcement
   - Reduced attack surface
   - Consistent session management

3. **Operational**
   - Single Docker container deployment
   - Simplified SSL certificate management
   - Unified logging and monitoring
   - Easier backup and disaster recovery

4. **Development**
   - Consistent development environment
   - Shared authentication logic
   - Easier integration testing
   - Single deployment pipeline

### Migration Strategy

#### Step 1: Prepare Central Auth (Week 1-2)
- Enhance qxli-ui authentication system
- Implement JWT token service
- Create user management APIs
- Add service authorization scopes

#### Step 2: Service Integration (Week 3-4)  
- Modify Langflow to accept external JWT tokens
- Configure n8n for external authentication
- Implement auth middleware for each service
- Test cross-service authentication

#### Step 3: Unified Routing (Week 5)
- Update Nginx configuration for path-based routing
- Implement auth_request validation
- Configure SSL for single domain
- Test end-to-end user flows

#### Step 4: Docker Unification (Week 6)
- Create unified Dockerfile
- Set up process management (supervisord/systemd)
- Configure service discovery
- Implement health checks

#### Step 5: Production Deployment (Week 7)
- Migrate DNS from subdomains to paths
- Deploy unified container
- Monitor and optimize performance
- User acceptance testing

### Potential Challenges & Solutions

1. **Service Conflicts**
   - Challenge: Port/resource conflicts in single container
   - Solution: Use different internal ports, nginx routing

2. **Authentication Complexity**
   - Challenge: Different auth mechanisms across services
   - Solution: Standardize on JWT with service-specific adapters

3. **Session State**
   - Challenge: Maintaining session across services
   - Solution: Stateless JWT tokens + Redis for session storage

4. **Container Size**
   - Challenge: Large unified container
   - Solution: Multi-stage builds, shared base images

5. **Development Workflow**
   - Challenge: Complex local development setup
   - Solution: Docker Compose with development overrides

### Alternative Approaches Considered

1. **OAuth2 Gateway (Keycloak/Auth0)**
   - Pros: Industry standard, full OAuth2 support
   - Cons: Additional complexity, external dependency

2. **API Gateway (Kong/Traefik)**
   - Pros: Advanced routing, plugin ecosystem
   - Cons: Learning curve, over-engineering for current needs

3. **Service Mesh (Istio)**
   - Pros: Advanced security, observability
   - Cons: Significant complexity overhead

### Recommended Approach

**Proceed with the reverse proxy-based SSO solution** using qxli-ui as the central authentication service. This approach:

- Leverages existing authentication infrastructure
- Minimizes external dependencies
- Provides clean migration path
- Offers good balance of features vs complexity
- Can be incrementally implemented

The solution is **technically feasible** and will provide significant UX improvements while simplifying deployment and maintenance.